import {merge} from "panda-parchment"
import createResource from "./resource"

assemble = (lib, basePath, resources) ->
  context = {basePath}
  new Proxy {},
    get: (target, name) ->
      if resources[name]?
        createResource lib,
        (merge context, {resourceName: name}),
        resources[name]

export default assemble
