import urlTemplate from "url-template"
import createMethod from "./method"
import {merge} from "panda-parchment"

# Join the basepath to the API endpoint path.
urlJoin = (base, path) ->
  if base[-1..] == "/"
    base[...-1] + path
  else
    base + path

createTemplate = (T) ->
  (description) -> urlTemplate.parse(T).expand description

createResource = (lib, context, {template, methods}) ->
  createPath = createTemplate template
  (description={}) ->
    new Proxy {},
      get: (target, name) ->
        path = createPath(description)
        url = urlJoin context.basePath, path

        if (method = methods[name])?
          {signatures} = method
          _context = merge context, {path, methodName: name, signatures}
          createMethod lib, _context, method
        else if name == "path"
          path
        else if name == "url"
          url
        else
          undefined

export default createResource
