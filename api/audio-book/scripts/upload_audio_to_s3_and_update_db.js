#!/usr/bin/env node

const crypto = require("crypto");
const fs = require("fs");
const https = require("https");
const path = require("path");
const { execFileSync } = require("child_process");

const ROOT = path.resolve(__dirname, "..");
const ENV_FILE = path.join(ROOT, ".env");

function parseEnv(filePath) {
  const env = {};
  const content = fs.readFileSync(filePath, "utf8");
  for (const line of content.split(/\r?\n/)) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith("#")) continue;
    const index = trimmed.indexOf("=");
    if (index < 0) continue;
    const key = trimmed.slice(0, index).trim();
    let value = trimmed.slice(index + 1).trim();
    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1);
    }
    env[key] = value;
  }
  return env;
}

const env = { ...parseEnv(ENV_FILE), ...process.env };
const bucket = required("AWS_BUCKET_NAME");
const region = required("AWS_REGION");
const accessKey = required("AWS_ACCESS_KEY");
const secretKey = required("AWS_SECRET_KEY");
const mysqlContainer = env.MYSQL_CONTAINER || "some-mysql";
const dbName = env.DB_NAME || "audio_book";
const dbUser = env.DB_USERNAME || "root";
const dbPassword = env.DB_PASSWORD || "12345";

function required(name) {
  const value = process.env[name] || parseEnv(ENV_FILE)[name];
  if (!value) throw new Error(`${name} is required`);
  return value;
}

function runDocker(args, input) {
  const baseArgs = ["docker", ...args];
  try {
    return execFileSync(baseArgs[0], baseArgs.slice(1), {
      input,
      encoding: "utf8",
      stdio: input == null ? ["ignore", "pipe", "pipe"] : ["pipe", "pipe", "pipe"],
    });
  } catch (error) {
    if (!env.SUDO_PASSWORD) throw error;
    execFileSync("sudo", ["-S", "-v"], {
      input: `${env.SUDO_PASSWORD}\n`,
      encoding: "utf8",
      stdio: ["pipe", "pipe", "pipe"],
    });
    return execFileSync("sudo", ["-n", ...baseArgs], {
      input,
      encoding: "utf8",
      stdio: input == null ? ["ignore", "pipe", "pipe"] : ["pipe", "pipe", "pipe"],
    });
  }
}

function mysql(sql) {
  return runDocker([
    "exec",
    "-i",
    mysqlContainer,
    "mysql",
    `-u${dbUser}`,
    `-p${dbPassword}`,
    "--default-character-set=utf8mb4",
    "-N",
    "-B",
    dbName,
  ], sql);
}

function sqlEscape(value) {
  return String(value).replace(/\\/g, "\\\\").replace(/'/g, "\\'");
}

function hmac(key, value, encoding) {
  return crypto.createHmac("sha256", key).update(value, "utf8").digest(encoding);
}

function sha256(value, encoding = "hex") {
  return crypto.createHash("sha256").update(value).digest(encoding);
}

function signingKey(dateStamp) {
  const kDate = hmac(`AWS4${secretKey}`, dateStamp);
  const kRegion = hmac(kDate, region);
  const kService = hmac(kRegion, "s3");
  return hmac(kService, "aws4_request");
}

function contentType(fileName) {
  const ext = path.extname(fileName).toLowerCase();
  if (ext === ".wav") return "audio/wav";
  if (ext === ".mp3") return "audio/mpeg";
  if (ext === ".m4a") return "audio/mp4";
  if (ext === ".ogg") return "audio/ogg";
  return "application/octet-stream";
}

function s3PutObject(localPath, key) {
  const body = fs.readFileSync(localPath);
  const now = new Date();
  const amzDate = now.toISOString().replace(/[:-]|\.\d{3}/g, "");
  const dateStamp = amzDate.slice(0, 8);
  const host = `${bucket}.s3.${region}.amazonaws.com`;
  const encodedKey = key.split("/").map(encodeURIComponent).join("/");
  const payloadHash = sha256(body);
  const headers = {
    "content-length": body.length,
    "content-type": contentType(localPath),
    host,
    "x-amz-content-sha256": payloadHash,
    "x-amz-date": amzDate,
  };

  const signedHeaders = Object.keys(headers).sort().join(";");
  const canonicalHeaders = Object.keys(headers)
    .sort()
    .map((name) => `${name}:${headers[name]}\n`)
    .join("");
  const canonicalRequest = [
    "PUT",
    `/${encodedKey}`,
    "",
    canonicalHeaders,
    signedHeaders,
    payloadHash,
  ].join("\n");
  const credentialScope = `${dateStamp}/${region}/s3/aws4_request`;
  const stringToSign = [
    "AWS4-HMAC-SHA256",
    amzDate,
    credentialScope,
    sha256(canonicalRequest),
  ].join("\n");
  const signature = hmac(signingKey(dateStamp), stringToSign, "hex");
  headers.authorization =
    `AWS4-HMAC-SHA256 Credential=${accessKey}/${credentialScope}, SignedHeaders=${signedHeaders}, Signature=${signature}`;

  return new Promise((resolve, reject) => {
    const req = https.request({
      method: "PUT",
      host,
      path: `/${encodedKey}`,
      headers,
    }, (res) => {
      const chunks = [];
      res.on("data", (chunk) => chunks.push(chunk));
      res.on("end", () => {
        const responseBody = Buffer.concat(chunks).toString("utf8");
        if (res.statusCode >= 200 && res.statusCode < 300) resolve();
        else reject(new Error(`S3 upload failed ${res.statusCode}: ${responseBody}`));
      });
    });
    req.on("error", reject);
    req.end(body);
  });
}

function localPathFor(rowPath, fileName) {
  const candidates = [
    rowPath,
    path.join(ROOT, "demo-assets", fileName),
  ].filter(Boolean);
  return candidates.find((item) => fs.existsSync(item));
}

async function main() {
  const rows = mysql(`
SELECT DISTINCT f.id, f.file_name, f.file_path, f.url
FROM file f
JOIN ebook_chapter c ON c.audio_file_id = f.id
WHERE f.type = 'audio'
ORDER BY f.id;
`).trim();

  if (!rows) {
    console.log("No audio files found.");
    return;
  }

  for (const line of rows.split(/\r?\n/)) {
    const [id, fileName, filePath, url] = line.split("\t");
    if ((filePath || url || "").startsWith("http")) {
      console.log(`skip file ${id}: already public URL`);
      continue;
    }

    const localPath = localPathFor(filePath, fileName);
    if (!localPath) {
      console.warn(`skip file ${id}: local file not found (${fileName})`);
      continue;
    }

    const key = `audio/demo-assets/${path.basename(fileName)}`;
    const publicUrl = `https://${bucket}.s3.${region}.amazonaws.com/${key}`;
    console.log(`upload file ${id}: ${localPath} -> ${publicUrl}`);
    await s3PutObject(localPath, key);
    mysql(`
UPDATE file
SET file_path = '${sqlEscape(publicUrl)}',
    url = '${sqlEscape(publicUrl)}'
WHERE id = ${Number(id)};
`);
  }

  console.log("Done.");
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
