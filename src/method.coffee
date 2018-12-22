import {merge} from "panda-parchment"
import buildAuthorization from "./authorization"
import check from "./validation"

method = (name) ->
  (fetch, description, body, shouldFollow) ->
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
    check expected, response, {path, method: name}

http =
  get: method "GET"
  post: method "POST"
  delete: method "DELETE"
  put: method "PUT"
  patch: method "PATCH"
  head: method "HEAD"
  options: method "OPTIONS"

createMethod = (fetch, context, method) ->
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
        description.headers["authorization"] = buildAuthorization authorization
    http[method.name] fetch, description, body, shouldFollow

export default createMethod
