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
      throw new Error "#{resourceName} #{methodName} request body failed validation
        #{JSON.stringify validator.errors}"

responseCheck = (lib, context, response) ->
  {resourceName, methodName, path, expected} = context
  methodName = methodName.toUpperCase()

  if response.status not in [expected.status, 304]
    throw new HttpError "#{resourceName} #{methodName} unexpected response status #{response.status} #{await response.text()}",
      response.status

  for header in expected.headers
    unless response.headers.get(header)?
      throw new Error "#{resourceName} #{methodName}
        Response header '#{header}' was not present or null"

  response


export {
  requestCheck
  responseCheck
}
