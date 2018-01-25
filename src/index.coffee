import {promise, merge, Method, curry, isObject, isString, base64} from "fairmont"
import {URL} from "url"
import {join} from "path"
import http2 from "http2"
import urlTemplate from "url-template"

class HttpError extends Error
  constructor: (message, @code) ->
    super message
    @statusCode = @code

connect = (url) -> http2.connect url

request = ({client, headers, options={}, body}) ->
  promise (y, n) ->
    data = ""
    status = undefined

    client.once "error", n

    req = client.request headers, options
    req.write body if body

    req.once "error", (e) -> n e
    req.on "response", (headers, flags) -> status = headers[":status"]
    req.on "data", (chunk) -> data += chunk
    req.on "end", -> y {data, status}
    req.end()

statusCheck = (expected, response) ->
  console.log response
  {data, status} = response
  if status && status == expected[0]
    # TODO: make this sensitive to mediatype
    try
      JSON.parse data
    catch
      data
  else
    throw new HttpError data, status



method = (name) ->
  (client, description, body) ->
    {path, expected, headers} = description
    headers = merge headers,
      ":method": name
      ":path": path

    options = if body then {} else endStream: true
    context = {client, headers, options, body}
    statusCheck expected, await request context


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
    path = join context.basePath, createPath(description)
    new Proxy {},
      get: (target, name) ->
        if (method = methods[name])?
          method.name = name
          expected = method.signatures.response.status
          context = merge {path, expected}, context
          createMethod context, method

createClient = (client, basePath, resources) ->
  context = {client, basePath}
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

createMethod = ({client, path, expected}, method) ->
  headers = {}
  description = {path, headers, expected}
  (methodArgs) ->
    if methodArgs
      {body, authorization} = methodArgs
      if body?
        # TODO: this will later rely on the method signature
        body = JSON.stringify body
        description.headers["content-type"] = "application/json"
      if method.name in ["get", "put", "post", "patch"]
        description.headers["accept"] = "application/json"
      if authorization?
        description.headers["authorization"] = createAuthorization authorization
    http[method.name] client, description, body


discover = (url, client) ->
  client ?= connect url
  {pathname: basePath} = new URL url

  {resources} = await http.get client, {path: basePath, expected: [200]}

  {
    hangup: -> client.destroy()
    client: createClient client, basePath, resources
  }


skyClient = {
  discover
}

export default skyClient
export {discover}
