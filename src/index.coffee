import urlTemplate from "url-template"
import {curry} from "fairmont-core"
import {merge, isObject, isString, base64} from "fairmont-helpers"
import {Method} from "fairmont-multimethods"

# Join the basepath to the API endpoint path.
urlJoin = (base, path) ->
  if base[-1..] == "/"
    base[...-1] + path
  else
    base + path

skyClient = (discoveryURL, fetch) ->
  if !(fetch ?= window?.fetch)?
    throw new Error "Provide fetch API, ex: fetch-h2"

  class HttpError extends Error
    constructor: (message, @status) ->
      super message

  statusCheck = (expected, response) ->
    {status, statusText} = response
    if status && status == expected[0]
      data = ""
      try
        # TODO: make this sensitive to mediatype
        data = await response.text()
        JSON.parse data
      catch e
        data
    else
      throw new HttpError statusText, status


  method = (name) ->
    (description, body, shouldFollow) ->
      {path, expected, headers} = description

      # Setup the fetch init object
      init = {
        method: name
        headers
        mode: "cors"
        redirect: shouldFollow
      }
      init.body = body if body

      response = await fetch path, init
      statusCheck expected, response


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

  createResource = (context, {uriTemplate, methods}) ->
    createPath = createTemplate uriTemplate
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
          createResource context, resources[name]

  createAuthorization = Method.create()

  Method.define createAuthorization, isObject, (schemes) ->
    for name, value of schemes
      createAuthorization name, value

  isScheme = curry (scheme, name) -> scheme == name.toLowerCase()
  isBasic = isScheme "basic"
  isBearer = isScheme "bearer"

  Method.define createAuthorization, isBasic, isObject,
    (name, {login, password}) -> "Basic " + base64 "#{login}:#{password}"

  Method.define createAuthorization, isBearer, isString,
    (name, token) -> "Bearer #{token}"

  createMethod = ({path, expected}, method) ->
    headers = {}
    description = {path, headers, expected}
    (methodArgs) ->
      if methodArgs
        {body, authorization, shouldFollow=false} = methodArgs
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
