import Generic from "panda-generics"
import {isObject, isString} from "panda-parchment"
import {encode as decodeUTF8} from "@stablelib/utf8"
import {encode as encodeBase64} from "@stablelib/base64"
{create, define} = Generic

isScheme = (scheme) ->
  (name) -> scheme == name.toLowerCase()
isBasic = isScheme "basic"
isBearer = isScheme "bearer"
isCapability = isScheme "capability"

authorization = create
  name: "Panda-Sky-Client: authorization"
  description: "Creates authorization headers for a given HTTP request"

define authorization, isString, (header) -> header

define authorization, isObject, (schemes) ->
  for name, value of schemes
    authorization name, value

define authorization, isBasic, isObject,
  (name, {login, password}) ->
    "Basic " + encodeBase64 decodeUTF8 "#{login}:#{password}"

define authorization, isBearer, isString,
  (name, token) -> "Bearer #{token}"

define authorization, isCapability, isString,
  (name, token) -> "X-Capability #{token}"

export default authorization
