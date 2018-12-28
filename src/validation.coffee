class HttpError extends Error
  constructor: (message, @status) ->
    super message

check = (expected, response, request) ->
  if response.status != expected.status
    message = "#{response.status} Panda Sky Client failure for #{request.method} #{expected.resource} (#{request.path}) #{response.statusText}"
    console.error message
    throw new HttpError message, response.status

  for header in expected.headers
    unless response.headers.get(header)?
      message = "invalid response header on #{request.method} #{expected.resource} (#{request.path}) #{header} was not present or null"
      console.warn message
      # throw new Error message

  response


export default check
