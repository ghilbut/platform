// src/index.ts
import { S3Client, HeadObjectCommand } from "@aws-sdk/client-s3";
var BUCKET = "__CDN_BUCKET__";
var s3 = new S3Client({ region: "us-east-1" });
async function headObject(key) {
  try {
    await s3.send(new HeadObjectCommand({ Bucket: BUCKET, Key: key }));
    return true;
  } catch {
    return false;
  }
}
function notFound() {
  return {
    status: "404",
    statusDescription: "Not Found"
  };
}
var handler = async (event) => {
  const request = event.Records[0].cf.request;
  const uri = request.uri;
  const clientType = request.headers["x-client-type"]?.[0]?.value ?? "";
  const isSpa = clientType.toLowerCase() === "spa";
  const rawKey = uri.replace(/^\//, "");
  if (!isSpa) {
    if (rawKey && await headObject(rawKey)) {
      request.uri = `/${rawKey}`;
      return request;
    }
    return notFound();
  }
  const slashIdx = rawKey.indexOf("/");
  const prefix = slashIdx >= 0 ? rawKey.slice(0, slashIdx + 1) : rawKey + "/";
  const path = slashIdx >= 0 ? rawKey.slice(slashIdx + 1) : "";
  if (path && await headObject(`${prefix}${path}`)) {
    request.uri = `/${prefix}${path}`;
    return request;
  }
  const segments = path.split("/").filter(Boolean);
  const maxDepth = segments.length > 0 ? segments.length - 1 : 0;
  for (let depth = maxDepth; depth >= 0; depth--) {
    const dirPart = segments.slice(0, depth).join("/");
    const indexKey = `${prefix}${dirPart ? `${dirPart}/` : ""}index.html`;
    if (await headObject(indexKey)) {
      request.uri = `/${indexKey}`;
      return request;
    }
  }
  return notFound();
};
export {
  handler
};
