class HttpError extends Error
  constructor: (message, @status) ->
    super message

# TODO: We need resource definition validation here.
# TODO: This assumes the "schema" library passed in is AJV, but we need to make this more generic in the future.
requestCheck = (lib, context) ->
  {resourceName, methodName, signatures, body} = context
  methodName = methodName.toUpperCase()
  {schema} = signatures.request

  if lib.validator? && schema?
    validator = lib.validator()
    isValid = validator.validate schema, JSON.parse body
    if !isValid
      errors = JSON.stringify validator.errors
      console.warn "Panda Sky Client: #{resourceName} #{methodName.toUpperCase()} -- Request body failed validation"
      console.warn errors
      console.warn body: JSON.parse body
      throw new Error errors

responseCheck = (lib, context, response) ->
  {resourceName, methodName, path, expected} = context
  methodName = methodName.toUpperCase()

  if response.status not in [expected.status, 304]
    message = "#{response.status} Panda Sky Client: #{resourceName} #{methodName} -- Unexpected response status from #{path} #{await response.text()}"
    console.warn message
    throw new HttpError message, response.status

  for header in expected.headers
    unless response.headers.get(header)?
      throw new Error "Panda Sky Client: #{resourceName} #{methodName} --
        Response header '#{header}' was not present or null"

  response


export {
  requestCheck
  responseCheck
}
