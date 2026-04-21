/**
 * CLOUDFLARE WORKER REVERSE PROXY - ULTIMATE VERSION
 * Hỗ trợ: Custom User/Pass, ENV Auth Toggle, Wildcard, Web Panel
 */

const ADMIN_PATH = "/manage-my-proxy"; // Đường dẫn trang quản lý

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const hostname = url.hostname;

    // 1. XỬ LÝ TRANG ADMIN PANEL
    if (url.pathname === ADMIN_PATH) {
      return handleAdminPanel(request, env);
    }

    // 2. TÌM KIẾM TARGET TRONG KV
    let targetHost = await env.PROXY_KV.get(hostname);

    // Thử tìm Wildcard nếu không thấy domain chính xác
    if (!targetHost) {
      const parts = hostname.split('.');
      if (parts.length >= 3) {
        const wildcardPattern = "*." + parts.slice(1).join('.');
        targetHost = await env.PROXY_KV.get(wildcardPattern);
      }
    }

    if (!targetHost) {
      return new Response("404 - Domain chưa cấu hình proxy.", { status: 404 });
    }

    // 3. XỬ LÝ REQUEST PHÍA SERVER GỐC
    const cleanTarget = targetHost.replace(/^https?:\/\//, '').split('/')[0];
    const targetUrl = new URL(request.url);
    targetUrl.hostname = cleanTarget;
    targetUrl.protocol = "https:";

    const newHeaders = new Headers(request.headers);
    newHeaders.set("Host", cleanTarget);
    newHeaders.set("X-Forwarded-Host", hostname);
    newHeaders.set("X-Real-IP", request.headers.get("cf-connecting-ip") || "");

    const requestInit = {
      method: request.method,
      headers: newHeaders,
      redirect: "manual"
    };

    if (request.method !== "GET" && request.method !== "HEAD") {
      requestInit.body = request.body;
    }

    try {
      const response = await fetch(targetUrl.toString(), requestInit);
      return new Response(response.body, response);
    } catch (e) {
      return new Response("502 Bad Gateway - Lỗi server gốc: " + e.message, { status: 502 });
    }
  }
};

// --- GIAO DIỆN QUẢN LÝ ---
async function handleAdminPanel(request, env) {
  const url = new URL(request.url);
  
  // KIỂM TRA TRẠNG THÁI BẢO MẬT (AUTH_ENABLED)
  const isAuthEnabled = env.AUTH_ENABLED === "true";
  
  if (isAuthEnabled) {
    const auth = request.headers.get("Authorization");
    const user = env.ADMIN_USERNAME || "admin";
    const pass = env.ADMIN_PASSWORD || "password";
    
    const expectedAuth = `Basic ${btoa(user + ":" + pass)}`;
    
    if (!auth || auth !== expectedAuth) {
      return new Response("Cần đăng nhập để tiếp tục", {
        status: 401,
        headers: { "WWW-Authenticate": 'Basic realm="Proxy Admin"' }
      });
    }
  }

  // Xử lý POST (Lưu/Xóa mapping)
  if (request.method === "POST") {
    const formData = await request.formData();
    const action = formData.get("action");
    const pDom = formData.get("proxy_domain")?.trim().toLowerCase();
    const tDom = formData.get("target_domain")?.trim().toLowerCase();

    if (action === "add" && pDom && tDom) {
      await env.PROXY_KV.put(pDom, tDom);
    } else if (action === "delete" && pDom) {
      await env.PROXY_KV.delete(pDom);
    }
    return new Response(null, { status: 302, headers: { "Location": url.pathname } });
  }

  // Lấy danh sách từ KV
  const list = await env.PROXY_KV.list();
  let rows = "";
  for (const key of list.keys) {
    const val = await env.PROXY_KV.get(key.name);
    rows += `<tr>
      <td><code>${key.name}</code></td>
      <td><code>${val}</code></td>
      <td>
        <form method="POST" style="margin:0"><input type="hidden" name="action" value="delete"><input type="hidden" name="proxy_domain" value="${key.name}"><button class="btn-del">Xóa</button></form>
      </td>
    </tr>`;
  }

  const html = `<!DOCTYPE html><html><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Admin Panel</title><style>
    body{font-family:sans-serif;background:#f4f7f6;padding:20px}
    .card{max-width:800px;margin:0 auto;background:#fff;padding:30px;border-radius:10px;box-shadow:0 2px 10px rgba(0,0,0,0.1)}
    input{padding:10px;margin-right:10px;border:1px solid #ddd;border-radius:5px;width:30%}
    button{padding:10px 20px;border:none;border-radius:5px;cursor:pointer;font-weight:700}
    .btn-add{background:#28a745;color:#fff}
    .btn-del{background:#dc3545;color:#fff}
    table{width:100%;border-collapse:collapse;margin-top:20px}
    th,td{padding:12px;text-align:left;border-bottom:1px solid #eee}
    code{background:#eee;padding:3px 6px;border-radius:4px}
    .status-bar{background:#e9ecef;padding:10px;border-radius:5px;margin-bottom:20px;font-size:14px}
  </style></head><body><div class="card">
    <h2>⚙️ Proxy Admin Panel</h2>
    <div class="status-bar">Chế độ bảo mật: <b>${isAuthEnabled ? '🔴 ĐANG BẬT' : '🟢 ĐANG TẮT'}</b> (Chỉnh tại ENV)</div>
    <form method="POST"><input type="hidden" name="action" value="add"><input type="text" name="proxy_domain" placeholder="Domain Proxy" required><input type="text" name="target_domain" placeholder="Domain Đích" required><button class="btn-add">Thêm mới</button></form>
    <table><thead><tr><th>Proxy</th><th>Target</th><th>Xóa</th></tr></thead><tbody>${rows || '<tr><td colspan="3">Trống</td></tr>'}</tbody></table>
  </div></body></html>`;

  return new Response(html, { headers: { "Content-Type": "text/html; charset=utf-8" } });
}
