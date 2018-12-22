import {curry} from "panda-garden"
import {Method} from "panda-generics"
import {isObject, isString} from "panda-parchment"

# TODO: replace this with a more robust string encode/decode tool.
import nacl from "tweetnacl-util"
{decodeBase64, decodeUTF8, encodeBase64, encodeUTF8} = nacl

authorization = Method.create()

Method.define authorization, isObject, (schemes) ->
  for name, value of schemes
    authorization name, value

isScheme = curry (scheme, name) -> scheme == name.toLowerCase()
isBasic = isScheme "basic"
isBearer = isScheme "bearer"

Method.define authorization, isBasic, isObject,
  (name, {login, password}) ->
    "Basic " + encodeBase64 decodeUTF8 "#{login}:#{password}"

Method.define authorization, isBearer, isString,
  (name, token) -> "Bearer #{token}"

export default authorization
