/**
 * AltMount Proxy Worker — whitelist reverse proxy (dành cho Cloudflare UI)
 *
 * Cách dùng:
 *   1. Cloudflare Dashboard -> Workers & Pages -> Create Worker
 *   2. Xoá code mẫu, dán toàn bộ file này vào, Deploy
 *   3. Settings -> Variables -> Add variable:
 *        ORIGIN = http://<ALTMOUNT_HOST>:<PORT>   (vd: http://1.2.3.4:8001)
 *      (tuỳ chọn nâng cao: thêm PROXY_SHARED_SECRET để gate thêm route API)
 *
 * Whitelist (mọi path khác -> 403):
 *   POST /api/nzb/streams              native NZB streams API (long-poll 5-10 phút)
 *   GET/HEAD /api/files/stream         endpoint stream THẬT (Range/206/ETag passthrough)
 *   GET/POST /sabnzbd/api              SABnzbd-compatible API
 *   /webdav, /webdav/*                 WebDAV fallback (PROPFIND/GET/PUT/...)
 *   OPTIONS                            preflight CORS
 *
 * Lưu ý: origin tự auth (X-Api-Key, download_key, JWT/basic WebDAV). Worker không
 * thêm auth riêng. Stream passthrough KHÔNG buffer -> giữ 206/Range, an toàn RAM.
 */

const ROUTES = [
  // Native NZB streams API - AIOStreams gọi (kèm X-Api-Key). Block 5-10 phút OK.
  { methods: ["POST"], test: (p) => p === "/api/nzb/streams" },
  // Stream thật - ServeContent: Range/If-Range/206/ETag/Last-Modified/Accept-Ranges.
  { methods: ["GET", "HEAD"], test: (p) => p === "/api/files/stream" },
  // SABnzbd-compatible API (fallback). Lưu ý: /api/sabnzbd/api KHÔNG tồn tại trên
  // origin (SPA fallback trả HTML) nên không whitelist.
  { methods: ["GET", "POST"], test: (p) => p === "/sabnzbd/api" },
  // WebDAV fallback - mọi method.
  { test: (p) => p === "/webdav" || p.startsWith("/webdav/") },
];

function isAllowed(method, pathname) {
  return ROUTES.some((r) => (!r.methods || r.methods.includes(method)) && r.test(pathname));
}

// Các route API mà PROXY_SHARED_SECRET (nếu bật) sẽ gate.
// KHÔNG gate stream - player chỉ gửi download_key trong query, không gửi header.
function isApiRoute(pathname) {
  return (
    pathname === "/api/nzb/streams" ||
    pathname === "/sabnzbd/api"
  );
}

function json(status, body) {
  const resp = new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json; charset=utf-8" },
  });
  resp.headers.set("Access-Control-Allow-Origin", "*");
  return resp;
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const method = request.method;
    const pathname = url.pathname;

    if (!env.ORIGIN) {
      return json(500, {
        error: "Missing ORIGIN",
        detail: "Set environment variable ORIGIN (vd: http://<ALTMOUNT_HOST>:<PORT>)",
      });
    }

    // Preflight CORS - cho phép mọi path (request thật vẫn bị whitelist chặn).
    if (method === "OPTIONS") {
      return new Response(null, {
        status: 204,
        headers: {
          "Access-Control-Allow-Origin": "*",
          "Access-Control-Allow-Methods":
            "GET, HEAD, POST, PUT, DELETE, PROPFIND, PROPPATCH, MKCOL, COPY, MOVE, LOCK, UNLOCK, OPTIONS",
          "Access-Control-Allow-Headers":
            "X-Api-Key, X-Proxy-Key, Authorization, Content-Type, Range, If-Range, Depth, Destination, Overwrite, If-Modified-Since, Lock-Token, Timeout",
          "Access-Control-Max-Age": "86400",
        },
      });
    }

    // 1) Whitelist.
    if (!isAllowed(method, pathname)) {
      return json(403, {
        error: "Forbidden",
        detail: `Route ${method} ${pathname} is not whitelisted`,
      });
    }

    // 2) Optional shared-secret gate (chỉ route API).
    if (env.PROXY_SHARED_SECRET && isApiRoute(pathname)) {
      const key = request.headers.get("X-Proxy-Key") ?? "";
      if (key !== env.PROXY_SHARED_SECRET) {
        return json(401, { error: "Unauthorized", detail: "X-Proxy-Key required" });
      }
    }

    // 3) Forward tới origin, giữ nguyên path + query.
    const originUrl = new URL(env.ORIGIN);
    originUrl.pathname = pathname;
    originUrl.search = url.search;

    const headers = new Headers(request.headers);
    // Giữ Host của worker: nếu AltMount chưa set Stremio.BaseURL, resolveBaseURL
    // dùng Hostname() -> Host = worker giúp stream URL trỏ về worker.
    headers.set("Host", url.host);
    headers.set("X-Forwarded-Host", url.host);
    headers.set("X-Forwarded-Proto", "https");
    headers.set("X-Forwarded-For", request.headers.get("cf-connecting-ip") ?? "");

    let resp;
    try {
      resp = await fetch(originUrl.toString(), {
        method,
        headers,
        body: request.body, // stream body cho POST (form nzb_url)
        redirect: "manual",
      });
    } catch (err) {
      return json(502, { error: "Bad Gateway", detail: String(err) });
    }

    // Passthrough trọn vẹn: giữ status (206!), headers, stream body - KHÔNG buffer.
    const out = new Response(resp.body, resp);
    if (!out.headers.has("Access-Control-Allow-Origin")) {
      out.headers.set("Access-Control-Allow-Origin", "*");
    }
    out.headers.set(
      "Access-Control-Expose-Headers",
      "Content-Range, Accept-Ranges, ETag, Content-Disposition, WWW-Authenticate"
    );
    return out;
  },
};
