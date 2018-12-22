import {merge} from "panda-parchment"
import createResource from "./resource"

assemble = (fetch, basePath, resources) ->
  context = {basePath}
  new Proxy {},
    get: (target, name) ->
      if resources[name]?
        createResource fetch,
        (merge context, {resourceName: name}),
        resources[name]

export default assemble
