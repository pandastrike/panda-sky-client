import urlTemplate from "url-template"
import {curry} from "panda-garden"
import {merge, isObject, isString} from "panda-parchment"
import {Method} from "panda-generics"
import log from "./log"

# TODO: replace this with a more robust string encode/decode tool.
import nacl from "tweetnacl-util"
{decodeBase64, decodeUTF8, encodeBase64, encodeUTF8} = nacl

# Join the basepath to the API endpoint path.
urlJoin = (base, path) ->
  if base[-1..] == "/"
    base[...-1] + path
  else
    base + path

skyClient = (discoveryURL, fetch, loggingFlag) ->
  if !(fetch ?= window?.fetch)?
    throw new Error "Provide fetch API, ex: fetch-h2"

  if loggingFlag
    fetch = log fetch

  class HttpError extends Error
    constructor: (message, @status) ->
      super message

  statusCheck = (expected, response, request) ->
    {status, statusText} = response
    if status && status == expected[0]
      response
    else
      throw new HttpError "Panda Sky Client failure for #{request.method} #{request.path} #{statusText}", status

  method = (name) ->
    (description, body, shouldFollow) ->
      {path, expected, headers, resourceName} = description

      # Setup the fetch init object
      init = {
        resourceName
        method: name
        headers
        mode: "cors"
      }

      init.redirect = shouldFollow if shouldFollow
      init.body = body if body

      response = await fetch path, init
      statusCheck expected, response, {path, method: name}


  http =
    get: method "GET"
    post: method "POST"
    delete: method "DELETE"
    put: method "PUT"
    patch: method "PATCH"
    head: method "HEAD"
    options: method "OPTIONS"

  createTemplate = (T) ->
    (description) -> urlTemplate.parse(T).expand description

  createResource = (context, {template, methods}) ->
    createPath = createTemplate template
    (description={}) ->
      path = urlJoin context.basePath, createPath(description)
      new Proxy {},
        get: (target, name) ->
          if (method = methods[name])?
            method.name = name
            expected = method.signatures.response.status
            context = merge {path, expected}, context
            createMethod context, method

  createClient = (basePath, resources) ->
    context = {basePath}
    new Proxy {},
      get: (target, name) ->
        if resources[name]?
          createResource (merge context, {resourceName: name}), resources[name]

  createAuthorization = Method.create()

  Method.define createAuthorization, isObject, (schemes) ->
    for name, value of schemes
      createAuthorization name, value

  isScheme = curry (scheme, name) -> scheme == name.toLowerCase()
  isBasic = isScheme "basic"
  isBearer = isScheme "bearer"

  Method.define createAuthorization, isBasic, isObject,
    (name, {login, password}) ->
      "Basic " + encodeBase64 decodeUTF8 "#{login}:#{password}"

  Method.define createAuthorization, isBearer, isString,
    (name, token) -> "Bearer #{token}"

  createMethod = (context, method) ->
    description = merge context, {headers: {}}
    (methodArgs) ->
      if methodArgs
        {body, authorization, shouldFollow} = methodArgs
        if body?
          # TODO: this will later rely on the method signature
          body = JSON.stringify body
          description.headers["content-type"] = "application/json"
        if method.name in ["get", "put", "post", "patch"]
          description.headers["accept"] = "application/json"
        if authorization?
          description.headers["authorization"] = createAuthorization authorization
      http[method.name] description, body, shouldFollow


  # With everything defined, use the discovery endpoint, parse to build the client and then return the client.
  response = await fetch discoveryURL
  {resources} = await response.json()
  createClient discoveryURL, resources

export default skyClient
