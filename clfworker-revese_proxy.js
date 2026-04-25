/**
 * CLOUDFLARE WORKER REVERSE PROXY - PRO RESPONSIVE VERSION
 * Hỗ trợ Mobile + Desktop, Fix lỗi UI, Cập nhật thông minh
 */

const ADMIN_PATH = "/manage-my-proxy";

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
  const isAuthEnabled = env.AUTH_ENABLED === "true";
  
  // BẢO MẬT
  if (isAuthEnabled) {
    const auth = request.headers.get("Authorization");
    const user = env.ADMIN_USERNAME || "admin";
    const pass = env.ADMIN_PASSWORD || "password";
    
    if (!auth || auth !== `Basic ${btoa(user + ":" + pass)}`) {
      return new Response("Cần đăng nhập để tiếp tục", {
        status: 401,
        headers: { "WWW-Authenticate": 'Basic realm="Proxy Admin"' }
      });
    }
  }

  // XỬ LÝ LƯU & XÓA (POST)
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

  // LẤY DANH SÁCH TỪ KV VÀ VẼ GIAO DIỆN
  const list = await env.PROXY_KV.list();
  let rows = "";
  for (const key of list.keys) {
    const val = await env.PROXY_KV.get(key.name);
    
    // Bỏ qua giá trị rác/null
    if (!val) continue; 

    rows += `<tr>
      <td><code>${key.name}</code></td>
      <td><code>${val}</code></td>
      <td>
        <div class="action-btns">
          <button type="button" class="btn-edit" onclick="editMapping('${key.name}', '${val}')">Sửa</button>
          <form method="POST" style="margin:0; flex:1;">
            <input type="hidden" name="action" value="delete">
            <input type="hidden" name="proxy_domain" value="${key.name}">
            <button class="btn-del" onclick="return confirm('Chắc chắn xóa domain này?')">Xóa</button>
          </form>
        </div>
      </td>
    </tr>`;
  }

  const html = `<!DOCTYPE html><html><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1"><title>Proxy Admin Panel</title><style>
    :root { --primary: #007bff; --danger: #dc3545; --warn: #ffc107; --bg: #f4f7f6; }
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background: var(--bg); padding: 15px; line-height: 1.6; margin: 0; color: #333; }
    .card { max-width: 900px; margin: 0 auto; background: #fff; padding: 25px; border-radius: 12px; box-shadow: 0 4px 20px rgba(0,0,0,0.05); }
    h2 { margin-top: 0; border-bottom: 2px solid #eee; padding-bottom: 15px; font-size: 22px; }
    
    /* Responsive Form */
    .form-group { display: flex; flex-wrap: wrap; gap: 10px; margin-bottom: 25px; }
    input { flex: 1 1 250px; padding: 12px 15px; border: 1px solid #ddd; border-radius: 8px; font-size: 15px; box-sizing: border-box; transition: border 0.2s; }
    input:focus { border-color: var(--primary); outline: none; box-shadow: 0 0 0 3px rgba(0,123,255,0.1); }
    
    /* Buttons */
    button { padding: 12px 15px; border: none; border-radius: 8px; cursor: pointer; font-weight: 600; font-size: 14px; transition: 0.2s; text-align: center; white-space: nowrap; }
    .btn-add { background: var(--primary); color: #fff; flex: 1 1 120px; }
    .btn-add:hover { background: #0056b3; }
    .btn-edit { background: var(--warn); color: #000; flex: 1; }
    .btn-edit:hover { background: #e0a800; }
    .btn-del { background: var(--danger); color: #fff; width: 100%; }
    .btn-del:hover { background: #c82333; }
    .action-btns { display: flex; gap: 6px; }

    /* Responsive Table */
    .table-responsive { overflow-x: auto; background: #fff; border-radius: 8px; border: 1px solid #eee; }
    table { width: 100%; border-collapse: collapse; min-width: 500px; }
    th, td { padding: 14px 15px; text-align: left; border-bottom: 1px solid #eee; }
    th { background: #f8f9fa; color: #555; text-transform: uppercase; font-size: 12px; letter-spacing: 0.5px; }
    code { background: #f1f3f5; padding: 4px 8px; border-radius: 6px; font-family: ui-monospace, monospace; font-size: 13px; color: #d63384; word-break: break-all; }
    
    .status-bar { background: #e9ecef; padding: 12px 15px; border-radius: 8px; margin-bottom: 25px; font-size: 14px; color: #444; display: flex; align-items: center; justify-content: space-between; flex-wrap: wrap; gap: 10px; }
    .badge { padding: 4px 8px; border-radius: 4px; font-size: 12px; font-weight: bold; }
    .badge-on { background: #ffeeba; color: #856404; }
    .badge-off { background: #d4edda; color: #155724; }

    /* Mobile Adjustments */
    @media (max-width: 600px) {
      body { padding: 10px; }
      .card { padding: 15px; }
      .action-btns { flex-direction: column; }
      th, td { padding: 10px; }
    }
  </style></head><body><div class="card">
    <h2>🚀 Proxy Admin Panel</h2>
    <div class="status-bar">
      <span>Trạng thái bảo mật (Auth):</span>
      <span class="badge ${isAuthEnabled ? 'badge-on' : 'badge-off'}">${isAuthEnabled ? '🔴 ĐANG BẬT' : '🟢 ĐANG TẮT'}</span>
    </div>
    
    <form class="form-group" method="POST">
      <input type="hidden" name="action" value="add">
      <input type="text" id="input_proxy" name="proxy_domain" placeholder="Domain Proxy (VD: hello.domain.com)" required autocomplete="off">
      <input type="text" id="input_target" name="target_domain" placeholder="Domain Đích (VD: my-server.com)" required autocomplete="off">
      <button type="submit" class="btn-add" id="btn_submit">Lưu Cấu Hình</button>
    </form>

    <div class="table-responsive">
      <table>
        <thead><tr><th>Domain Proxy (Lối vào)</th><th>Target Host (Đích đến)</th><th style="width: 140px;">Thao tác</th></tr></thead>
        <tbody>${rows || '<tr><td colspan="3" style="text-align:center;color:#888;padding:30px;">Chưa có mapping nào được tạo.</td></tr>'}</tbody>
      </table>
    </div>
  </div>
  
  <script>
    function editMapping(proxy, target) {
      document.getElementById('input_proxy').value = proxy;
      document.getElementById('input_target').value = target;
      document.getElementById('btn_submit').innerText = "Cập nhật";
      document.getElementById('btn_submit').style.background = "#28a745";
      window.scrollTo({ top: 0, behavior: 'smooth' });
      document.getElementById('input_target').focus();
    }
  </script>
  </body></html>`;

  return new Response(html, { headers: { "Content-Type": "text/html; charset=utf-8" } });
}
