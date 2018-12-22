import log from "./log"
import assemble from "./assemble"

skyClient = (discoveryURL, fetch, loggingFlag) ->
  # In the browser, we have access to the Fetch API, but in Node, you need to supply your own.
  if !(fetch ?= window?.fetch)?
    throw new Error "Provide fetch API, ex: fetch-h2"

  # Provides debug level logging on network traffic from the client. Defaults to false.
  if loggingFlag
    fetch = log fetch

  # Fetch from the discovery endpoint, parse, assemble the client, then return.
  response = await fetch discoveryURL
  {resources} = await response.json()
  assemble fetch, discoveryURL, resources

export default skyClient
