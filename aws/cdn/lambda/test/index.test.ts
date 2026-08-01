import { describe, it, before, mock } from "node:test";
import assert from "node:assert/strict";

// ---------------------------------------------------------------------------
// Stub S3Client before importing the handler so the module picks up mocks
// ---------------------------------------------------------------------------

interface S3Response {
  Body?: { transformToString: (encoding?: string) => Promise<string> };
}

const s3Responses: Map<string, S3Response | "NOT_FOUND"> = new Map();

const mockSend = mock.fn(async (command: { input: { Key: string } }) => {
  const key = command.input.Key;
  const result = s3Responses.get(key);
  if (!result || result === "NOT_FOUND") {
    const err = new Error("NoSuchKey");
    (err as NodeJS.ErrnoException).name = "NoSuchKey";
    throw err;
  }
  return result;
});

// Patch the module registry so the handler imports our mock S3Client
mock.module("@aws-sdk/client-s3", {
  namedExports: {
    S3Client: class {
      send = mockSend;
    },
    HeadObjectCommand: class {
      input: { Bucket: string; Key: string };
      constructor(input: { Bucket: string; Key: string }) {
        this.input = input;
      }
    },
  },
});

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function makeEvent(uri: string, opts: { clientType?: string; querystring?: string } = {}) {
  const headers: Record<string, { key: string; value: string }[]> = {
    host: [{ key: "Host", value: "cloudfront-origin.amazonaws.com" }],
  };
  if (opts.clientType) {
    headers["x-client-type"] = [{ key: "X-Client-Type", value: opts.clientType }];
  }
  return {
    Records: [
      {
        cf: {
          request: {
            headers,
            uri,
            querystring: opts.querystring ?? "",
          },
        },
      },
    ],
  };
}

function setObject(key: string, content = "content") {
  s3Responses.set(key, {
    Body: {
      transformToString: async () => content,
    },
  });
}

function removeObject(key: string) {
  s3Responses.set(key, "NOT_FOUND");
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

describe("Lambda@Edge CDN handler", () => {
  let handler: (event: ReturnType<typeof makeEvent>) => Promise<unknown>;

  before(async () => {
    ({ handler } = await import("../src/index.ts"));
  });

  describe("file mode (no X-Client-Type header)", () => {
    before(() => {
      setObject("skins.ghilbut.com/assets/logo.png");
    });

    it("rewrites URI for existing object", async () => {
      const result = (await handler(makeEvent("/skins.ghilbut.com/assets/logo.png"))) as {
        uri: string;
      };
      assert.equal(result.uri, "/skins.ghilbut.com/assets/logo.png");
    });

    it("returns 404 status for missing object", async () => {
      removeObject("skins.ghilbut.com/assets/missing.png");
      const result = (await handler(makeEvent("/skins.ghilbut.com/assets/missing.png"))) as {
        status: string;
      };
      assert.equal(result.status, "404");
    });

    it("returns 404 for empty URI", async () => {
      const result = (await handler(makeEvent("/"))) as { status: string };
      assert.equal(result.status, "404");
    });

    it("passes through 404.html for CloudFront custom error page fetch", async () => {
      setObject("404.html");
      const result = (await handler(makeEvent("/404.html"))) as { uri: string };
      assert.equal(result.uri, "/404.html");
    });

    it("passes through 503.html for CloudFront custom error page fetch", async () => {
      setObject("503.html");
      const result = (await handler(makeEvent("/503.html"))) as { uri: string };
      assert.equal(result.uri, "/503.html");
    });
  });

  describe("spa mode (X-Client-Type: SPA)", () => {
    before(() => {
      setObject("devx.ghilbut.com/index.html");
      setObject("devx.ghilbut.com/app/index.html");
      setObject("devx.ghilbut.com/app/assets/logo.svg");
    });

    it("serves root index.html for prefixed / request", async () => {
      const result = (await handler(makeEvent("/devx.ghilbut.com/", { clientType: "SPA" }))) as {
        uri: string;
      };
      assert.equal(result.uri, "/devx.ghilbut.com/index.html");
    });

    it("serves exact key when it exists", async () => {
      const result = (await handler(
        makeEvent("/devx.ghilbut.com/app/assets/logo.svg", { clientType: "SPA" }),
      )) as { uri: string };
      assert.equal(result.uri, "/devx.ghilbut.com/app/assets/logo.svg");
    });

    it("falls back to nearest index.html", async () => {
      removeObject("devx.ghilbut.com/app/deep/page");
      removeObject("devx.ghilbut.com/app/deep/index.html");
      const result = (await handler(
        makeEvent("/devx.ghilbut.com/app/deep/page", { clientType: "SPA" }),
      )) as { uri: string };
      assert.equal(result.uri, "/devx.ghilbut.com/app/index.html");
    });

    it("falls back to root index.html when no closer one exists", async () => {
      removeObject("devx.ghilbut.com/other/page");
      removeObject("devx.ghilbut.com/other/index.html");
      const result = (await handler(
        makeEvent("/devx.ghilbut.com/other/page", { clientType: "SPA" }),
      )) as { uri: string };
      assert.equal(result.uri, "/devx.ghilbut.com/index.html");
    });

    it("returns 404 when no index.html found anywhere", async () => {
      removeObject("empty.ghilbut.com/page");
      removeObject("empty.ghilbut.com/index.html");
      const result = (await handler(
        makeEvent("/empty.ghilbut.com/page", { clientType: "SPA" }),
      )) as {
        status: string;
      };
      assert.equal(result.status, "404");
    });

    it("treats lowercase 'spa' as SPA mode", async () => {
      const result = (await handler(makeEvent("/devx.ghilbut.com/", { clientType: "spa" }))) as {
        uri: string;
      };
      assert.equal(result.uri, "/devx.ghilbut.com/index.html");
    });
  });
});
