import { describe, it } from "node:test";
import assert from "node:assert/strict";

// Mirrors viewer-request.js.tftpl with test data substituted for Terraform template variables.
function makeHandler(allowlist, redirectMap, spaHosts) {
  return function handler(event) {
    var request = event.request;

    delete request.headers["x-client-type"];

    var host = request.headers.host && request.headers.host.value;
    if (!host) {
      return {
        statusCode: 503,
        statusDescription: "Service Unavailable",
        headers: { "content-type": { value: "text/plain" } },
        body: "Service Unavailable",
      };
    }

    var ALLOWED = allowlist;
    var REDIRECTS = redirectMap;
    var SPA = spaHosts;

    if (ALLOWED.indexOf(host) < 0) {
      return {
        statusCode: 503,
        statusDescription: "Service Unavailable",
        headers: { "content-type": { value: "text/plain" } },
        body: "Service Unavailable",
      };
    }

    var redirectTarget = REDIRECTS[host];
    if (redirectTarget) {
      var redirectUri = request.uri || "/";
      var hostPrefix = "/" + host + "/";
      if (redirectUri.indexOf(hostPrefix) === 0) {
        redirectUri = "/" + redirectUri.slice(hostPrefix.length);
      } else if (redirectUri === "/" + host) {
        redirectUri = "/";
      }
      var qsParts = [];
      for (var qsKey in request.querystring) {
        var qsEntry = request.querystring[qsKey];
        var qsVals =
          qsEntry.multiValue && qsEntry.multiValue.length > 1
            ? qsEntry.multiValue
            : [{ value: qsEntry.value }];
        for (var qsIdx = 0; qsIdx < qsVals.length; qsIdx++) {
          qsParts.push(qsKey + "=" + qsVals[qsIdx].value);
        }
      }
      var qs = qsParts.length > 0 ? "?" + qsParts.join("&") : "";
      return {
        statusCode: 301,
        statusDescription: "Moved Permanently",
        headers: { location: { value: "https://" + redirectTarget + redirectUri + qs } },
      };
    }

    if (SPA.indexOf(host) >= 0) {
      request.headers["x-client-type"] = { value: "SPA" };
    }

    var uri = request.uri || "/";
    var prefix = "/" + host + "/";

    if (uri.indexOf(prefix) === 0) {
      return request;
    }

    if (uri === "/" || uri === "/" + host) {
      request.uri = prefix;
      return request;
    }

    request.uri = prefix + uri.replace(/^\/+/, "");
    return request;
  };
}

function makeEvent(host, uri, querystring = {}) {
  return {
    request: {
      headers: { host: { value: host } },
      uri,
      querystring,
    },
  };
}

const ALLOWED = ["xyz.ghilbut.com", "www.ghilbut.com", "devx.ghilbut.com"];
const REDIRECTS = { "xyz.ghilbut.com": "www.ghilbut.com" };
const SPA = ["devx.ghilbut.com"];
const handler = makeHandler(ALLOWED, REDIRECTS, SPA);

describe("viewer-request: redirect querystring serialization", () => {
  it("no querystring — Location has no trailing ?", () => {
    const result = handler(makeEvent("xyz.ghilbut.com", "/", {}));
    assert.equal(result.headers.location.value, "https://www.ghilbut.com/");
  });

  it("single query param is preserved", () => {
    const result = handler(makeEvent("xyz.ghilbut.com", "/", { a: { value: "1" } }));
    assert.equal(result.headers.location.value, "https://www.ghilbut.com/?a=1");
  });

  it("multiple query params are preserved", () => {
    const result = handler(
      makeEvent("xyz.ghilbut.com", "/", { a: { value: "1" }, b: { value: "2" } }),
    );
    const loc = result.headers.location.value;
    assert.ok(loc.startsWith("https://www.ghilbut.com/?"));
    assert.ok(loc.includes("a=1"));
    assert.ok(loc.includes("b=2"));
  });

  it("repeated key (multiValue) produces multiple key=value pairs", () => {
    const result = handler(
      makeEvent("xyz.ghilbut.com", "/", {
        a: { value: "1", multiValue: [{ value: "1" }, { value: "2" }] },
      }),
    );
    const loc = result.headers.location.value;
    assert.ok(loc.includes("a=1"));
    assert.ok(loc.includes("a=2"));
  });

  it("sub-path is preserved on redirect", () => {
    const result = handler(makeEvent("xyz.ghilbut.com", "/abc/def/ghi", {}));
    assert.equal(result.headers.location.value, "https://www.ghilbut.com/abc/def/ghi");
  });

  it("sub-path and query string are both preserved", () => {
    const result = handler(
      makeEvent("xyz.ghilbut.com", "/abc/def/ghi", { a: { value: "1" }, b: { value: "2" } }),
    );
    const loc = result.headers.location.value;
    assert.ok(loc.startsWith("https://www.ghilbut.com/abc/def/ghi?"));
    assert.ok(loc.includes("a=1"));
    assert.ok(loc.includes("b=2"));
  });

  it("Location header never contains [object Object]", () => {
    const result = handler(makeEvent("xyz.ghilbut.com", "/", { a: { value: "1" } }));
    assert.ok(!result.headers.location.value.includes("[object Object]"));
  });
});

describe("viewer-request: redirect status and non-redirect passthrough", () => {
  it("redirect returns 301", () => {
    const result = handler(makeEvent("xyz.ghilbut.com", "/", {}));
    assert.equal(result.statusCode, 301);
  });

  it("unknown host returns 503", () => {
    const result = handler(makeEvent("unknown.ghilbut.com", "/", {}));
    assert.equal(result.statusCode, 503);
  });

  it("SPA host gets x-client-type header", () => {
    const result = handler(makeEvent("devx.ghilbut.com", "/", {}));
    assert.equal(result.headers["x-client-type"].value, "SPA");
  });

  it("header injection is blocked for redirect host", () => {
    const event = makeEvent("xyz.ghilbut.com", "/", {});
    event.request.headers["x-client-type"] = { value: "injected" };
    const result = handler(event);
    assert.equal(result.statusCode, 301);
    assert.ok(!("x-client-type" in (result.headers || {})));
  });
});
