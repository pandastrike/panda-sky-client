import "babel-polyfill"
import {discover} from "./index"

#URL = "https://b1l5aw0zge.execute-api.us-west-2.amazonaws.com/staging/"
URL = "https://e1527lm922.execute-api.us-west-2.amazonaws.com/staging/"

do ->
  try
    {hangup, client} = await discover URL
    console.log "Final output from discover:", await client.blurb(key: "123").get()
  catch e
    console.error e.stack
  hangup()
