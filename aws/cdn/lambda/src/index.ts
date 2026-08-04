import { S3Client, HeadObjectCommand } from "@aws-sdk/client-s3";
import type { CloudFrontRequestEvent, CloudFrontResultResponse } from "aws-lambda";

declare const CDN_BUCKET: string;

const BUCKET = CDN_BUCKET;
const s3 = new S3Client({ region: "us-east-1" });

async function headObject(key: string): Promise<boolean> {
  try {
    await s3.send(new HeadObjectCommand({ Bucket: BUCKET, Key: key }));
    return true;
  } catch {
    return false;
  }
}

function notFound(): CloudFrontResultResponse {
  return {
    status: "404",
    statusDescription: "Not Found",
  };
}

export const handler = async (event: CloudFrontRequestEvent) => {
  const request = event.Records[0].cf.request;
  const uri = request.uri;

  // X-Client-Type is set exclusively by the viewer-request CloudFront Function.
  // viewer-request clears any client-supplied value before setting its own,
  // so this header can be trusted as authoritative.
  const clientType = request.headers["x-client-type"]?.[0]?.value ?? "";
  const isSpa = clientType.toLowerCase() === "spa";

  const rawKey = uri.replace(/^\//, "");

  if (!isSpa) {
    // File mode: exact S3 key only.
    // Also handles CloudFront custom error page fetches (/404.html, /503.html)
    // since viewer-request does not run for those internal requests.
    if (rawKey && (await headObject(rawKey))) {
      request.uri = `/${rawKey}`;
      return request;
    }
    return notFound();
  }

  // SPA mode: viewer-request guarantees URI is /{host}/... format.
  const slashIdx = rawKey.indexOf("/");
  const prefix = slashIdx >= 0 ? rawKey.slice(0, slashIdx + 1) : rawKey + "/";
  const path = slashIdx >= 0 ? rawKey.slice(slashIdx + 1) : "";

  if (path && (await headObject(`${prefix}${path}`))) {
    request.uri = `/${prefix}${path}`;
    return request;
  }

  // Walk up directories for index.html fallback.
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
