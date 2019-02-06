import {merge} from "panda-parchment"
import buildAuthorization from "./authorization"
import {requestCheck, responseCheck} from "./validation"

method = (name) ->
  (lib, context) ->
    # Setup the Fetch init object
    init = {
      method: name
      headers: context.headers
      mode: "cors"
    }

    init.redirect = context.shouldFollow if context.shouldFollow?
    init.body = context.body if context.body?

    requestCheck lib, context
    response = await lib.fetch context.path, init, context
    await responseCheck lib, context, response

http =
  get: method "GET"
  post: method "POST"
  delete: method "DELETE"
  put: method "PUT"
  patch: method "PATCH"
  head: method "HEAD"
  options: method "OPTIONS"

parseSignature = (signatures) ->
  {response} = signatures
  status = response.status[0]

  headers = []
  if status == 201
    headers.push "location"
  if response.cache?
    {etag, maxAge, lastModified} = response.cache
    if etag?
      headers.push "etag"
    if maxAge? || lastModified?
      headers.push "cache-control"

  {status, headers}

createMethod = (lib, context, method) ->
  (methodArgs) ->
    _context = merge context,
      headers: {}
      expected: parseSignature context.signatures

    if methodArgs
      {body, authorization, shouldFollow} = methodArgs
      _context.shouldFollow = shouldFollow
      if body?
        # TODO: this will later rely on the method signature
        _context.body = JSON.stringify body
        _context.headers["content-type"] = "application/json"
      if context.methodName in ["get", "put", "post", "patch"]
        _context.headers["accept"] = "application/json"
      if authorization?
        _context.headers["authorization"] = buildAuthorization authorization

    http[context.methodName] lib, _context

export default createMethod
