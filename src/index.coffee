import {} from "fairmont"
import http2 from "http2"
import qs from "querystring"
import urlTemplate from "url-template"


connect = (url) -> http2.connect url

request = (client, description, body) ->
  promise (y, n) ->
    client.once "error", n
    data = ""
    response = client.request description
    .once "error", n
    .on "data", (chunk) -> data += chunk
    .on "end", -> y JSON.parse data

method = (name) ->
  (client, description, body) ->
    {url} = description
    description[":method"] = name
    description[":url"] = url
    request client, description, body

http =
  get: method "GET"
  post: method "POST"
  delete: method "DELETE"
  put: method "PUT"
  patch: method "PATCH"
  head: method "HEAD"
  options: method "OPTIONS"

createTemplate = (template) ->
  templater = urlTemplate.parse template
  (description) -> templater.expand description


createClient = (client, resources) ->
  context = {client}
  new Proxy {},
    get: (name) ->
      if resources[name]?
        createResource context, resources[name]

createResource = (context, {template, methods}) ->
  createURL = createTemplate template
  (description={}) ->
    url = createURL description
    new Proxy {},
      get: (name) ->
        if (method = methods[name])?
          method.name = name
          context = merge {url}, context
          createMethod context, method

createMethod = ({client, url}, method) ->
  description = {url}
  (body) -> http[name] client, description, body


discover = (url, client) ->
  client ?= connect url
  {resources} = await http.get client, url
  createClient client, resources


skyClient = {
  discover
}

export default skyClient
export {discover}
