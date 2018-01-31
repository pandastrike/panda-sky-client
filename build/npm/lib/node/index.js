"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});

function _asyncToGenerator(fn) { return function () { var gen = fn.apply(this, arguments); return new Promise(function (resolve, reject) { function step(key, arg) { try { var info = gen[key](arg); var value = info.value; } catch (error) { reject(error); return; } if (info.done) { resolve(value); } else { return Promise.resolve(value).then(function (value) { step("next", value); }, function (err) { step("throw", err); }); } } return step("next"); }); }; }

var skyClient;

skyClient = (() => {
  var _ref = _asyncToGenerator(function* (discoveryURL) {
    var HttpError, Method, base64, createAuthorization, createClient, createMethod, createResource, createTemplate, curry, disconnectAll, fetch, http, isBasic, isBearer, isObject, isScheme, isString, merge, method, resources, response, statusCheck, urlTemplate;
    if (/^.*\/$/.test(discoveryURL)) {
      discoveryURL = discoveryURL.slice(0, -1);
    }
    // These node libraries will always get loaded / bundled.
    urlTemplate = yield Promise.resolve().then(() => require("url-template"));
    ({ curry } = yield Promise.resolve().then(() => require("fairmont-core")));
    ({ merge, isObject, isString, base64 } = yield Promise.resolve().then(() => require("fairmont-helpers")));
    ({ Method } = yield Promise.resolve().then(() => require("fairmont-multimethods")));
    // Dynamic imports based on whether or not we're in a browser.
    if (typeof window !== "undefined" && window !== null) {
      fetch = window.fetch;
      disconnectAll = void 0;
    } else {
      ({ fetch, disconnectAll } = yield Promise.resolve().then(() => require("fetch-h2")));
    }
    HttpError = class HttpError extends Error {
      constructor(message, status1) {
        super(message);
        this.status = status1;
      }

    };
    statusCheck = (() => {
      var _ref2 = _asyncToGenerator(function* (expected, response) {
        var data, e, status, statusText;
        ({ status, statusText } = response);
        if (status && status === expected[0]) {
          data = "";
          try {
            // TODO: make this sensitive to mediatype
            data = yield response.text();
            return JSON.parse(data);
          } catch (error) {
            e = error;
            return data;
          }
        } else {
          throw new HttpError(statusText, status);
        }
      });

      return function statusCheck(_x2, _x3) {
        return _ref2.apply(this, arguments);
      };
    })();
    method = function (name) {
      return (() => {
        var _ref3 = _asyncToGenerator(function* (description, body, shouldFollow) {
          var expected, headers, init, path, response;
          ({ path, expected, headers } = description);
          // Setup the fetch init object
          init = {
            method: name,
            headers,
            mode: "cors",
            redirect: shouldFollow
          };
          if (body) {
            init.body = body;
          }
          response = yield fetch(path, init);
          return statusCheck(expected, response);
        });

        return function (_x4, _x5, _x6) {
          return _ref3.apply(this, arguments);
        };
      })();
    };
    http = {
      get: method("GET"),
      post: method("POST"),
      delete: method("DELETE"),
      put: method("PUT"),
      patch: method("PATCH"),
      head: method("HEAD"),
      options: method("OPTIONS")
    };
    createTemplate = function (T) {
      return function (description) {
        return urlTemplate.parse(T).expand(description);
      };
    };
    createResource = function (context, { uriTemplate, methods }) {
      var createPath;
      createPath = createTemplate(uriTemplate);
      return function (description = {}) {
        var path;
        path = context.basePath + createPath(description);
        return new Proxy({}, {
          get: function (target, name) {
            var expected;
            if ((method = methods[name]) != null) {
              method.name = name;
              expected = method.signatures.response.status;
              context = merge({ path, expected }, context);
              return createMethod(context, method);
            }
          }
        });
      };
    };
    createClient = function (basePath, resources) {
      var context;
      context = { basePath };
      return new Proxy({}, {
        get: function (target, name) {
          if (resources[name] != null) {
            return createResource(context, resources[name]);
          }
        }
      });
    };
    createAuthorization = Method.create();
    Method.define(createAuthorization, isObject, function (schemes) {
      var name, results, value;
      results = [];
      for (name in schemes) {
        value = schemes[name];
        results.push(createAuthorization(name, value));
      }
      return results;
    });
    isScheme = curry(function (scheme, name) {
      return scheme === name.toLowerCase();
    });
    isBasic = isScheme("basic");
    isBearer = isScheme("bearer");
    Method.define(createAuthorization, isBasic, isObject, function (name, { login, password }) {
      return "Basic " + base64(`${login}:${password}`);
    });
    Method.define(createAuthorization, isBearer, isString, function (name, token) {
      return `Bearer ${token}`;
    });
    createMethod = function ({ path, expected }, method) {
      var description, headers;
      headers = {};
      description = { path, headers, expected };
      return function (methodArgs) {
        var authorization, body, ref, shouldFollow;
        if (methodArgs) {
          ({ body, authorization, shouldFollow = false } = methodArgs);
          if (body != null) {
            // TODO: this will later rely on the method signature
            body = JSON.stringify(body);
            description.headers["content-type"] = "application/json";
          }
          if ((ref = method.name) === "get" || ref === "put" || ref === "post" || ref === "patch") {
            description.headers["accept"] = "application/json";
          }
          if (authorization != null) {
            description.headers["authorization"] = createAuthorization(authorization);
          }
        }
        return http[method.name](description, body, shouldFollow);
      };
    };
    // With everything defined, use the discovery endpoint, parse to build the client and then return the client.
    response = yield fetch(discoveryURL);
    ({ resources } = yield response.json());
    return {
      disconnectAll,
      hangup: disconnectAll,
      client: createClient(discoveryURL, resources)
    };
  });

  return function skyClient(_x) {
    return _ref.apply(this, arguments);
  };
})();

exports.default = skyClient;