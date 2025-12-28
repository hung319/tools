// --- CẤU HÌNH ---
const USER_CONFIG = "eyJ1c2VybmFtZSI6Imh1bmciLCJwYXNzd29yZCI6Imh1bmciLCJ0cyI6MTc2NDcyNTIxNDA1NX0";
const UPSTREAM_HOST = "https://stremio.phim4k.xyz";

// User-Agent LG WebOS giả mạo
const LG_UA = "Mozilla/5.0 (Web0S; Linux/SmartTV) AppleWebKit/538.2 (KHTML, like Gecko) Large Screen Safari/538.2 LG Browser/7.00.00(LGE; WEBOS2; 04.06.25; 1; DTV_W15U); webOS.TV-2015; LG NetCast.TV-2013 Compatible (LGE, WEBOS2, wireless)";

export default {
    async fetch(request, env, ctx) {
        const url = new URL(request.url);
        const path = url.pathname;

        // 1. CORS & Redirect Root
        if (request.method === "OPTIONS") return new Response(null, { headers: corsHeaders() });
        if (path === "/" || path === "") {
            return Response.redirect(url.href.replace("https://", "stremio://") + "manifest.json", 301);
        }

        // --- ROUTE: PROXY STREAM (Tunneling) ---
        // Đây là nơi TV kết nối đến để lấy dữ liệu video
        if (path === "/proxy-stream") {
            const targetUrl = url.searchParams.get("q");
            if (!targetUrl) return new Response("Missing URL", { status: 400 });

            try {
                // Tạo headers mới để gửi đi (giả danh LG)
                const newHeaders = new Headers();
                newHeaders.set("User-Agent", LG_UA);
                newHeaders.set("Referer", "https://phim4k.xyz/");

                // QUAN TRỌNG: Forward header "Range" từ TV lên Server gốc
                // Để hỗ trợ tua phim (seeking)
                const range = request.headers.get("Range");
                if (range) {
                    newHeaders.set("Range", range);
                }

                // Gọi lên server Phim4K (hoặc link redirect)
                const response = await fetch(targetUrl, {
                    method: request.method,
                    headers: newHeaders,
                    redirect: "follow" // Tự động đi theo redirect đến link cuối cùng (Fshare/Gdrive)
                });

                // Chuẩn bị response trả về cho TV
                const responseHeaders = new Headers(response.headers);
                
                // Đảm bảo CORS
                responseHeaders.set("Access-Control-Allow-Origin", "*");
                responseHeaders.set("Access-Control-Allow-Headers", "Range");
                responseHeaders.set("Access-Control-Expose-Headers", "Content-Range, Content-Length");

                // Trả về luồng video (Stream Body)
                return new Response(response.body, {
                    status: response.status, // Thường là 200 hoặc 206 (Partial Content)
                    statusText: response.statusText,
                    headers: responseHeaders
                });

            } catch (e) {
                return new Response("Tunnel Error: " + e.message, { status: 502 });
            }
        }

        // --- ROUTE: ADDON LOGIC ---
        const targetUrl = `${UPSTREAM_HOST}/${USER_CONFIG}${path}`;

        try {
            const response = await fetch(targetUrl);
            if (!response.ok) return new Response(response.body, { status: response.status, headers: corsHeaders() });

            const data = await response.json();

            // Sửa Manifest
            if (path.endsWith("/manifest.json")) {
                data.id = "cf.phim4k.proxy.v7";
                data.name = "Phim4K VIP (Tunnel Fix)";
                data.description = "Stream qua Cloudflare Proxy (Hỗ trợ tua)";
                return jsonResponse(data);
            }

            // Sửa Stream JSON
            if (path.includes("/stream/") && data.streams && Array.isArray(data.streams)) {
                data.streams = data.streams.map(stream => {
                    // Biến đổi tất cả link thành link qua Tunnel của mình
                    if (stream.url) {
                        const encodedUrl = encodeURIComponent(stream.url);
                        // URL mới: https://worker.dev/proxy-stream?q=LINK_GOC
                        stream.url = `${url.origin}/proxy-stream?q=${encodedUrl}`;
                        
                        // Xóa behaviorHints cũ đi vì giờ Worker lo hết rồi
                        stream.behaviorHints = {
                            notWebReady: true,
                            bingeGroup: "phim4k-tunnel"
                        };
                        stream.title = (stream.title || "") + " [Tunnel]";
                    }
                    return stream;
                });
                return jsonResponse(data);
            }

            return jsonResponse(data);

        } catch (e) {
            return new Response(JSON.stringify({ error: e.message }), { headers: corsHeaders() });
        }
    }
};

// Helpers
function jsonResponse(obj) {
    return new Response(JSON.stringify(obj), {
        headers: { "Content-Type": "application/json; charset=utf-8", ...corsHeaders() }
    });
}
function corsHeaders() {
    return { 
        "Access-Control-Allow-Origin": "*", 
        "Access-Control-Allow-Methods": "GET, HEAD, OPTIONS",
        "Access-Control-Allow-Headers": "Range"
    };
}
