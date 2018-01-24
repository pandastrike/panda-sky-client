import {promise, merge, Method, curry, isObject, isString} from "fairmont"
import {URL} from "url"
import {join} from "path"
import http2 from "http2"
import urlTemplate from "url-template"


connect = (url) -> http2.connect url

request = (client, headers, options, body) ->
  console.log headers
  promise (y, n) ->
    data = ""
    client.once "error", n
    if options
      req = client.request headers, options
    else
      req = client.request headers

    body.pipe(req) if body

    req.once "error", (e) -> n e
    # req.on "response", (headers, flags) ->
    #   if headers.status >= 400
    #     console.log "error response", headers
    req.on "data", (chunk) -> data += chunk
    req.on "end", -> y JSON.parse data
    req.end()

method = (name) ->
  (client, description, body) ->
    headers =
      ":method": name
      ":path": description.path

    options = false
    if !body
      options = endStream: true

    request client, headers, options

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
          context = merge {path}, context
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
  (name, {login, password}) -> # ...

Method.define createAuthorization, isBearer, isString,
  (name, token) -> # ...

createMethod = ({client, path}, method) ->
  headers = {}
  description = {path, headers}
  (methodArgs) ->
    if methodArgs
      {body, authorization} = methodArgs
      if body?
        # TODO: this will later rely on the method signature
        description.headers["content-type"] = "application/json"
      if method.name in ["get", "put", "post", "patch"]
        description.headers["accept"] = "application/json"
      if authorization?
        description.headers["authorization"] = createAuthorization authorization
    http[method.name] client, description, body


discover = (url, client) ->
  client ?= connect url
  {pathname: basePath} = new URL url

  {resources} = await http.get client, {path: basePath}

  {
    hangup: -> client.destroy()
    client: createClient client, basePath, resources
  }


skyClient = {
  discover
}

export default skyClient
export {discover}
