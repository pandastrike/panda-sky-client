merge = (objects...) -> Object.assign {}, objects...

prototype = (value) -> if value? then Object.getPrototypeOf value

isPrototype = (p, value) -> p? && p == prototype value

isType = (type) ->
  (value) ->
    isPrototype type?.prototype, value

isString = isType String
isObject = isType Object

export {
  merge
  isObject
  isString
}
