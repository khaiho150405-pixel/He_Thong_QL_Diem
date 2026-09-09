import { createServer } from "node:http";
import { readFile } from "node:fs/promises";
import path from "node:path";
const root = path.resolve("apps/client_flutter/build/web");
const types = {
  ".html": "text/html; charset=utf-8",
  ".js": "text/javascript",
  ".json": "application/json",
  ".wasm": "application/wasm",
  ".png": "image/png",
  ".ttf": "font/ttf",
};
createServer(async (req, res) => {
  try {
    const name = decodeURIComponent(
      new URL(req.url, "http://localhost").pathname,
    );
    const file = path.resolve(root, "." + name);
    if (file !== root && !file.startsWith(root + path.sep)) {
      res.writeHead(403);
      res.end();
      return;
    }
    const target = file === root ? path.join(root, "index.html") : file;
    let data;
    try {
      data = await readFile(target);
    } catch {
      res.writeHead(404);
      res.end();
      return;
    }
    res.writeHead(200, {
      "content-type": types[path.extname(target)] ?? "application/octet-stream",
    });
    res.end(data);
  } catch {
    res.writeHead(400);
    res.end();
  }
}).listen(8080, "127.0.0.1", () =>
  console.log("Flutter web: http://localhost:8080"),
);
