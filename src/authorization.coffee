import Generic from "panda-generics"
import {isObject, isString} from "./utils"

# TODO: replace this with a more robust string encode/decode tool.
import nacl from "tweetnacl-util"
{decodeBase64, decodeUTF8, encodeBase64, encodeUTF8} = nacl
{create, define} = Generic

isScheme = (scheme) ->
  (name) -> scheme == name.toLowerCase()
isBasic = isScheme "basic"
isBearer = isScheme "bearer"

authorization = create
  name: "Panda-Sky-Client: authorization"
  description: "Creates authorization headers for a given HTTP request"

define authorization, isObject, (schemes) ->
  for name, value of schemes
    authorization name, value

define authorization, isBasic, isObject,
  (name, {login, password}) ->
    "Basic " + encodeBase64 decodeUTF8 "#{login}:#{password}"

define authorization, isBearer, isString,
  (name, token) -> "Bearer #{token}"

export default authorization
