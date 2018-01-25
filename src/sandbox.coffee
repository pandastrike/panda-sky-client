import "babel-polyfill"
import {discover} from "./index"

#URL = "https://b1l5aw0zge.execute-api.us-west-2.amazonaws.com/staging/"
URL = "https://70s09y8o9a.execute-api.us-west-2.amazonaws.com/staging"

# do ->
#   try
#     {hangup, client} = await discover URL
#     console.log "Final output from discover:", await client.blurb(key: "123").get()
#   catch e
#     console.error e.statusCode
#     console.error e.stack
#   hangup()

do ->
  try
    {hangup, client} = await discover URL
    res = await client.blurbs().post body: content: "hello"
      # body:
      #   content: "Hello World"
    console.log res
  catch e
    console.error e.statusCode
    console.error e.stack
  hangup()

# do ->
#   try
#     {hangup, client} = await discover URL
#     key = 'parting-launder-elastic-myself-tiptop-defeat-snaking-proved-herself-boxing-fame'
#     res = await client.blurb({key}).get()
#     console.log res
#   catch e
#     console.error e.statusCode
#     console.error e.stack
#   hangup()

# do ->
#   try
#     {hangup, client} = await discover URL
#
#     key = 'parting-launder-elastic-myself-tiptop-defeat-snaking-proved-herself-boxing-fame'
#
#     body = content: "Hello, David!"
#     authorization = bearer: 'aghast-propose-tinfoil-reach-clutch-glazing-helium-geiger-motor-scale-sizably'
#
#     res = await client.blurb({key}).put({body, authorization})
#
#     console.log res
#   catch e
#     console.error e.statusCode
#     console.error e.stack
#   hangup()




# do ->
#   try
#     {hangup, client} = await discover URL
#     key = 'parting-launder-elastic-myself-tiptop-defeat-snaking-proved-herself-boxing-fame'
#     authorization = bearer: 'aghast-propose-tinfoil-reach-clutch-glazing-helium-geiger-motor-scale-sizably'
#     res = await client.blurb({key}).delete {authorization}
#     console.log res
#   catch e
#     console.error e.statusCode
#     console.error e.stack
#   hangup()
