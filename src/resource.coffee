import {merge} from "panda-parchment"
import urlTemplate from "url-template"
import createMethod from "./method"

parseSignature = (resource, {signatures, name}) ->
  {response} = signatures
  expectedStatus = response.status[0]
  expectedHeaders = []

  if expectedStatus == 201
    expectedHeaders.push "location"
  {etag, maxAge, lastModified} = response.cache?
  if etag?
    expectedHeaders.push "etag"
  if maxAge? || lastModified?
    expectedHeaders.push "cache-control"

  resource: resource
  method: name
  status: expectedStatus
  headers: expectedHeaders

# Join the basepath to the API endpoint path.
urlJoin = (base, path) ->
  if base[-1..] == "/"
    base[...-1] + path
  else
    base + path

createTemplate = (T) ->
  (description) -> urlTemplate.parse(T).expand description

createResource = (fetch, context, {template, methods}) ->
  createPath = createTemplate template
  (description={}) ->
    path = urlJoin context.basePath, createPath(description)
    new Proxy {},
      get: (target, name) ->
        if (method = methods[name])?
          method.name = name
          expected = parseSignature context.resourceName, method
          context = merge {path, expected}, context
          createMethod fetch, context, method

export default createResource
