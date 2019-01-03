import {merge} from "./utils"

json = (obj) -> console.log "JSON", JSON.stringify obj

isCacheHit = (response) ->
  if value = response.headers.get("x-cache")
    /^Hit/.test value
  else
    false

Log = (fn) ->
  (args...) ->
    if args[2]
      {methodName, resourceName} = args[2]
    else
      methodName = "get"
      resourceName = "discovery"

    tag = "#{resourceName + methodName.toUpperCase()}"

    json
      networkAttempt: true
      tag: tag
    try
      start = Date.now()
      result = await fn args...
      duration = Date.now() - start

      out =
        "#{tag}": duration
        networkSuccess: true
        cacheHit: isCacheHit result
        tag: tag

      if /^5[0-9][0-9]/.test result.status
        json merge out, {Status500Class: true}
      else if /^4[0-9][0-9]/.test result.status
        json merge out, {Status400Class: true}
      else
        json out

      # Don't forget to return the actual result after we finish logging.
      return result

    catch e
      json
        networkFail: true
        tag: tag
      console.log e
      throw new Error e

export default Log
