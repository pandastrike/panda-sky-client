"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _urlTemplate = require("url-template");

var _urlTemplate2 = _interopRequireDefault(_urlTemplate);

var _fairmontCore = require("fairmont-core");

var _fairmontHelpers = require("fairmont-helpers");

var _fairmontMultimethods = require("fairmont-multimethods");

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _asyncToGenerator(fn) { return function () { var gen = fn.apply(this, arguments); return new Promise(function (resolve, reject) { function step(key, arg) { try { var info = gen[key](arg); var value = info.value; } catch (error) { reject(error); return; } if (info.done) { resolve(value); } else { return Promise.resolve(value).then(function (value) { step("next", value); }, function (err) { step("throw", err); }); } } return step("next"); }); }; }

var skyClient, urlJoin;

// Join the basepath to the API endpoint path.
urlJoin = function (base, path) {
  if (base.slice(-1) === "/") {
    return base.slice(0, -1) + path;
  } else {
    return base + path;
  }
};

skyClient = (() => {
  var _ref = _asyncToGenerator(function* (discoveryURL, fetch) {
    var HttpError, createAuthorization, createClient, createMethod, createResource, createTemplate, http, isBasic, isBearer, isScheme, method, resources, response, statusCheck;
    if ((fetch != null ? fetch : fetch = typeof window !== "undefined" && window !== null ? window.fetch : void 0) == null) {
      throw new Error("Provide fetch API, ex: fetch-h2");
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

      return function statusCheck(_x3, _x4) {
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

        return function (_x5, _x6, _x7) {
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
        return _urlTemplate2.default.parse(T).expand(description);
      };
    };
    createResource = function (context, { template, methods }) {
      var createPath;
      createPath = createTemplate(template);
      return function (description = {}) {
        var path;
        path = urlJoin(context.basePath, createPath(description));
        return new Proxy({}, {
          get: function (target, name) {
            var expected;
            if ((method = methods[name]) != null) {
              method.name = name;
              expected = method.signatures.response.status;
              context = (0, _fairmontHelpers.merge)({ path, expected }, context);
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
    createAuthorization = _fairmontMultimethods.Method.create();
    _fairmontMultimethods.Method.define(createAuthorization, _fairmontHelpers.isObject, function (schemes) {
      var name, results, value;
      results = [];
      for (name in schemes) {
        value = schemes[name];
        results.push(createAuthorization(name, value));
      }
      return results;
    });
    isScheme = (0, _fairmontCore.curry)(function (scheme, name) {
      return scheme === name.toLowerCase();
    });
    isBasic = isScheme("basic");
    isBearer = isScheme("bearer");
    _fairmontMultimethods.Method.define(createAuthorization, isBasic, _fairmontHelpers.isObject, function (name, { login, password }) {
      return "Basic " + (0, _fairmontHelpers.base64)(`${login}:${password}`);
    });
    _fairmontMultimethods.Method.define(createAuthorization, isBearer, _fairmontHelpers.isString, function (name, token) {
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
    return createClient(discoveryURL, resources);
  });

  return function skyClient(_x, _x2) {
    return _ref.apply(this, arguments);
  };
})();

exports.default = skyClient;