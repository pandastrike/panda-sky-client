import Method from "panda-generics"
import {isObject, isString, toJSON} from "panda-parchment"
import {encode as decodeUTF8} from "@stablelib/utf8"
import {encode as encodeBase64} from "@stablelib/base64"

isScheme = (scheme) ->
  (name) -> scheme == name.toLowerCase()
isBasic = isScheme "basic"
isBearer = isScheme "bearer"
isCapability = isScheme "capability"
isSigil = isScheme "sigil"

authorization = Method.create
  name: "authorization"
  description: "This creates your Authorization HTTP header based on input configuration"

Method.define authorization, isString, (header) -> header

Method.define authorization, isObject, (schemes) ->
  for name, value of schemes
    authorization name, value

Method.define authorization, isBasic, isObject,
  (name, {login, password}) ->
    "Basic " + encodeBase64 decodeUTF8 "#{login}:#{password}"

Method.define authorization, isBearer, isString,
  (name, token) -> "Bearer #{token}"

Method.define authorization, isSigil, isString,
  (name, token) -> "Sigil #{token}"

Method.define authorization, isCapability, isString,
  (name, token) -> "X-Capability #{token}"

export default authorization
