# Panda Sky Client
__Auto-Assembling Client for APIs deployed with Panda Sky__

# Quickstart
### Browser
The Sky client accesses `window.fetch` automatically in the browser, so just install with npm and use your favorite bundler to get it into the browser.

```shell
$ npm install panda-sky-client --save
```

```coffeescript
import discover from "panda-sky-client"
do ->
  client = await discover url
```

### Node
But if you want to use the Sky client from Node—which is great for writing API tests, for example—you need to provide a Fetch interface when you instantiate the client. We currently recommend the [npm package http-h2][http-h2].  You can use it easily like this:

```shell
$ npm install panda-sky-client http-h2 --save
```

```coffeescript
import discover from "panda-sky-client"
import {fetch, disconnectAll} from "fetch-h2"
do ->
  client = await discover url, fetch
```


# API Walkthrough
## A Self-Assembling API Client
Panda Sky and its accompanying ecosystem are designed to make writing serverless apps painless.  The Sky client makes it easy to use a Sky API, integrating with code running in a browser or Node server/lambda.

### Interface-First Design
As you may recall, Panda Sky focuses on [interface-first design][ifd].  The API description you write is authoritative. Define it once, and Sky uses it to both orchestrate Cloud resources in your deployment _and_ generate a client that consumes that API.

[ifd]:https://www.pandastrike.com/posts/20171205-introducing-panda-sky#interface-first-design

Here's a hypothetical blogging app's API description.
```yaml
resources:
  discovery:
    template: "/"
    description: "Discovery endpoint for the client."
    methods:
      get:
        signatures:
          request: {}
          response:
            status: [200]

  blurbs:
    template: "/blurbs"
    description: "Virtual collection of blog posts"
    methods:
      post:
        signatures:
          request: {}
          response:
            status: [201, 422]

  blurb:
    template: "/blurbs/{key}"
    description: "Individual posts"
    methods:
      get:
        signatures:
          request: {}
          response:
            status: [200, 404]
      put:
        signatures:
          request:
            authorization: ["Bearer"]
          response:
            status: [200, 401, 404]
```

We define a discovery resource that responds with the API description for the client to use. We also define two more resources with HTTP methods that can act upon them. The Sky client parses this to generate functions that issue well-formed HTTP requests.  Just give the Sky client the URL of the discovery resource to get started.

```coffeescript
import discover from "panda-sky-client"
clientPromise = discover "https://api.example-blogging-app.com"

document.addEventListener "DOMContentLoaded", ->
  client = await clientPromise

  document.querySelector "#publishButton"
  .addEventListener "click", (e) ->
    body = document.querySelector("#postTextBox").value
    {key, editKey} = await client.blurbs().post {body}
```

We import `discover` from the client and pass it the discovery URL.  `discover` returns a promise that resolves an instantiated client. We setup a button click event listener that uses the client to issue an API request and create a new blog post.

The client generates functions that return [Promises][promises].  Those promises resolve with response data and reject if the response status code is unexpected (ex, `404` from a GET request).  We use the relatively new [`await` operator][await] to allow the promise to resolve asynchronously, making the client functions easy to place into `try...catch` control structures.  Or, you could directly use the Promise `.then()` / `.catch()` interface.

For client errors, you may examine the property `status` to get the error response's HTTP integer code.

[await]:https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/await
[promises]:https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise

### Focus on Resources, Not Building URLs
As a developer implementing against a Sky API, the Sky client shields you from considering URL structure details.  What is the path for a given resource?  Are there path or querystring parameters, or both?

It shouldn't matter.

You are writing client code that consumes an API, but your concerns are separate from that API's implementation details. Opaque URLs allow you to decouple your code from the interface you are consuming, to draw boundaries on your mental model and avoid brittle integrations.

The top-level functions on the instantiated client return _resources_.  The arguments to these functions are the parameters needed to specify a _particular_ resource.  In the above example, the `blurbs` resource didn't need any, so we invoked it with `blurbs()`.  But to GET a specific `blurb` resource, we need its `key`.  Place that parameter into the invocation, like this.

```coffeescript
do ->
  key = "55d4xOv0JRCxooRnNoHtGQ"
  content = await client.blurb({key}).get()
```

The Sky client uses the RFC specification for URI template expansion, specifically sections [3.2.2][3.2.2] and [3.2.8][3.2.8], to map the values from the object passed to `blurb` to the parameters specified in the template.

[3.2.2]:https://tools.ietf.org/html/rfc6570#section-3.2.2
[3.2.8]:https://tools.ietf.org/html/rfc6570#section-3.2.8

```yaml
template: "/blurbs/{key}"
```

That template could include query string information (3.2.8), or could have a different path structure, like
```yaml
template: "/blurbs/drafts/{key}{?author,status}"
```

But you don't have to worry about anything other than the parameters.  

```coffeescript
do ->
  key = "55d4xOv0JRCxooRnNoHtGQ"
  author = "David Harper"
  status = 2

  content = await client.blurb({key, author, status}).get()
```

You have plenty of things to do, so allow the Sky client to handle URL construction for you.

### HTTP/2 Comes Standard
The Sky client wraps the [Fetch API][fetch], so you get HTTP/2 features, like multiplexing, binary encoding efficiency, and header compression; all without any effort from you (Recall that Panda Sky also _deploys_ APIs and custom domains that use HTTP/2 by default).

The Sky client accesses `window.fetch` automatically in the browser.  But if you want to use the Sky client from Node—which is great for writing API tests, for example—you need to provide a Fetch interface when you instanciate the client. We currently recommend the [npm package http-h2][http-h2].  You can use it easily like this:

[fetch]:https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API
[http-h2]:https://www.npmjs.com/package/fetch-h2

```coffeescript
import discover from "panda-sky-client"
import {fetch, disconnectAll} from "fetch-h2"
do ->
  client = await discover url, fetch
```

> In a Node process, you want the function `disconnectAll` to gracefully close the connections formed by the low-level HTTP/2 client before exiting. In the browser, that connection is managed by the vendor's implementation.

### Functional Reactive Ajax
The history of [Ajax][ajax] in the browser is now almost 2 decades long. [jQuery freed us][jquery-ajax] from writing XMLHttpRequest callback boilerplate, and its chaining structure remains influential.  But we explored a functional style when we built the Sky client.

[ajax]:https://en.wikipedia.org/wiki/Ajax_(programming)
[jquery-ajax]:http://api.jquery.com/jquery.ajax/

While you can use the client with a chain notation:
```coffeescript
do ->
  client = await discover endpointURL

  {key, editKey} = await client
  .blurbs()
  .post body: "Hello World!"
```

The client is composed entirely of functions, so you can also destructure the constituent functions for reuse or composition.
```coffeescript
do ->
  {blurbs, blurb} = await discover endpointURL
  {post} = blurbs()

  {key, editKey} = await post body: "Hello World!"
```

This gets interesting because [functional reactive programming (FRP)][frp] uses flows to provide robust data handling in event-based designs.  The Sky client's functions are a perfect fit for that design.

[frp]:/posts/20151130-what-the-hell-is-functional-reactive-programming
