import { createServer } from "node:http";
import { readFile } from "node:fs/promises";
import path from "node:path";
const root = path.resolve("apps/client_flutter/build/web");
const types = {
  ".html": "text/html; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".mjs": "text/javascript; charset=utf-8",
  ".json": "application/json",
  ".wasm": "application/wasm",
  ".png": "image/png",
  ".jpg": "image/jpeg",
  ".jpeg": "image/jpeg",
  ".webp": "image/webp",
  ".svg": "image/svg+xml",
  ".ico": "image/x-icon",
  ".ttf": "font/ttf",
  ".otf": "font/otf",
  ".woff": "font/woff",
  ".woff2": "font/woff2",
  ".css": "text/css",
  ".map": "application/json",
};
createServer(async (req, res) => {
  try {
    const url = new URL(req.url, "http://localhost");
    const pathname = decodeURIComponent(url.pathname);
    let target = path.resolve(root, "." + pathname);
    if (target !== root && !target.startsWith(root + path.sep)) {
      res.writeHead(403);
      res.end();
      return;
    }
    if (target === root) {
      target = path.join(root, "index.html");
    }
    let data;
    try {
      data = await readFile(target);
    } catch {
      // SPA Fallback for client-side routing when URL has no extension
      if (!path.extname(pathname)) {
        try {
          target = path.join(root, "index.html");
          data = await readFile(target);
        } catch {
          res.writeHead(404);
          res.end();
          return;
        }
      } else {
        res.writeHead(404);
        res.end();
        return;
      }
    }
    res.writeHead(200, {
      "content-type": types[path.extname(target)] ?? "application/octet-stream",
      "cache-control":
        "no-store, no-cache, must-revalidate, proxy-revalidate, max-age=0",
    });

    res.end(data);
  } catch {
    res.writeHead(400);
    res.end();
  }
}).listen(8080, "0.0.0.0", () =>
  console.log("Flutter web: http://localhost:8080"),
);
