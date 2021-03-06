import log from "./log"
import assemble from "./assemble"

skyClient = (discoveryURL, options) ->
  if options?
    {fetch, validator, logging, headers={}} = options
  # In the browser, we have access to the Fetch API, but in Node, you need to supply your own.
  if !(fetch ?= window?.fetch)?
    throw new Error "Provide fetch API, ex: fetch-h2"

  # Provides debug level logging on network traffic from the client. Defaults to false.
  if logging?
    fetch = log fetch

  # Fetch from the discovery endpoint and parse,
  _headers = Accept: "application/json"
  _headers[k] = v for k, v of headers

  response = await fetch discoveryURL,
    method: "GET"
    headers: _headers

  {resources} = await response.json()

  # lib is the low level interfaces to make and validate the HTTP request.
  lib = {fetch, validator, headers}

  # assemble the client for external use.
  assemble lib, discoveryURL, resources

export default skyClient
