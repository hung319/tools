// ==UserScript==
// @name         YoHoHo.io Turbo Double-Spam + ESP (CezDev)
// @namespace    http://tampermonkey.net/
// @version      2.4
// @description  Double-Click trong lúc Spam + ESP xuyên tường. T: Auto-Charge | G: Hold-to-Spam | E: ESP.
// @author       CezDev
// @match        https://yohoho.io/*
// @grant        none
// ==/UserScript==

(function() {
    'use strict';

    let config = { autoCharge: true, spamEnabled: true, espEnabled: true };
    let isUserHolding = false;
    let isLocked = false; 
    let spamInterval = null;
    let espReady = false; // PIXI đã móc được stage chưa (dùng cho UI)

    // --- 1. UI (Góc dưới trái) ---
    const ui = document.createElement('div');
    Object.assign(ui.style, {
        position: 'fixed', bottom: '20px', left: '20px', padding: '12px',
        backgroundColor: 'rgba(0, 0, 0, 0.9)', color: '#00ff00',
        fontFamily: 'Consolas, monospace', zIndex: '10000', borderRadius: '8px',
        border: '1px solid #00ff00', pointerEvents: 'none', fontSize: '13px',
        lineHeight: '1.5'
    });
    document.body.appendChild(ui);

    const updateUI = () => {
        const espState = espReady ? (config.espEnabled ? 'ON' : 'OFF') : 'WAIT';
        const espColor = espReady ? (config.espEnabled ? '#ff9800' : '#ff4444') : '#888888';
        ui.innerHTML = `
            <b style="color:#fbff00">CEZDEV TURBO V2.4</b><br>
            <span style="color: ${config.autoCharge ? '#00ff00' : '#ff4444'}">[T] AUTO-CHARGE: ${config.autoCharge ? 'ON' : 'OFF'}</span><br>
            <span style="color: ${config.spamEnabled ? '#00ffff' : '#ff4444'}">[G] DOUBLE-SPAM: ${config.spamEnabled ? 'ON' : 'OFF'}</span><br>
            <span style="color: ${espColor}">[E] ESP: ${espState}</span>
        `;
    };
    updateUI();

    // --- 2. Core Actions ---
    // The page can hold more than one canvas (game + this script's ESP overlay),
    // so always pick the biggest non-overlay canvas as the game surface.
    const getGameCanvas = () => {
        let best = null, bestArea = 0;
        const list = document.getElementsByTagName('canvas');
        for (let i = 0; i < list.length; i++) {
            const c = list[i];
            if (c.id === 'cezdev-esp-overlay') continue;
            const area = (c.width || 0) * (c.height || 0);
            if (area > bestArea) { bestArea = area; best = c; }
        }
        return best || document.body;
    };

    const send = (type) => {
        const canvas = getGameCanvas();
        canvas.dispatchEvent(new MouseEvent(type, { bubbles: true, cancelable: true, button: 0 }));
    };

    // Vòng lặp Spam với kỹ thuật Double-Click
    const startSpam = () => {
        if (spamInterval) return;
        spamInterval = setInterval(() => {
            if (isUserHolding && config.spamEnabled) {
                // Nhát chém 1
                send('mouseup');
                setTimeout(() => { 
                    if (isUserHolding) {
                        send('mousedown');
                        // Nhát chém 2 (Double click ngay lập tức)
                        setTimeout(() => {
                            if (isUserHolding) {
                                send('mouseup');
                                setTimeout(() => { if (isUserHolding) send('mousedown'); }, 5);
                            }
                        }, 10); 
                    }
                }, 5);
            }
        }, 70); // Tăng nhịp gốc lên 70ms để tránh lag do Double-Click quá nhanh
    };

    const stopSpam = () => {
        clearInterval(spamInterval);
        spamInterval = null;
    };

    // --- 3. Event Listeners ---
    window.addEventListener('mousedown', (e) => {
        if (e.isTrusted) {
            isUserHolding = true;
            isLocked = true;
            if (config.spamEnabled) {
                send('mouseup'); // Nhả phát gồng để bắt đầu chuỗi Turbo
                startSpam();
            }
        }
    }, true);

    window.addEventListener('mouseup', (e) => {
        if (e.isTrusted) {
            isUserHolding = false;
            stopSpam();
            setTimeout(() => {
                isLocked = false;
                if (config.autoCharge && !isUserHolding) send('mousedown');
            }, 200); 
        }
    }, true);

    window.addEventListener('keydown', (e) => {
        const key = e.key.toLowerCase();
        if (key === 't') {
            config.autoCharge = !config.autoCharge;
            config.autoCharge ? send('mousedown') : send('mouseup');
            updateUI();
        }
        if (key === 'g') {
            config.spamEnabled = !config.spamEnabled;
            updateUI();
        }
        if (key === 'e') {
            config.espEnabled = !config.espEnabled;
            updateUI();
        }
    });

    // Watchdog duy trì gồng (Fix lỗi web không ổn định)
    setInterval(() => {
        if (config.autoCharge && !isUserHolding && !isLocked) {
            send('mousedown');
        }
    }, 500);

    // --- 4. ESP (xuyên tường) ---
    // yohoho.io render bằng PIXI 4; state người chơi nằm trong closure nên không
    // đọc được từ global. Cách duy nhất ổn định: móc PIXI.WebGLRenderer.render
    // để lấy display list (stage), rồi đọc vị trí các node người chơi từ đó.
    //   - 1 container chứa nhãn tên (mỗi con có PIXI.Text)
    //   - 1 container chứa thân, đúng gấp đôi số con (2 node/người, cặp liền kề)
    //   - getGlobalPosition() -> toạ độ pixel màn hình (camera đã áp)
    //   - người ngoài tầm nhìn bị "park" ở ~(-1.07e6) -> bỏ qua
    // Game render nhiều stage trên cùng canvas (thế giới + UI), nên giữ danh
    // sách mọi stage đã thấy (mới nhất trước) rồi chọn stage chứa người chơi.
    const _stages = []; // [{ stage, view }]
    let pixiCanvas = null;
    let _groups = null;
    let _lastGroupScan = 0;

    const OVERLAY_ID = 'cezdev-esp-overlay';
    const overlay = document.createElement('canvas');
    overlay.id = OVERLAY_ID;
    overlay.style.cssText = 'position:fixed;top:0;left:0;width:100%;height:100%;pointer-events:none;z-index:9998;';
    document.body.appendChild(overlay);
    const ovCtx = overlay.getContext('2d');

    const hookPixi = () => {
        const P = window.PIXI;
        if (!P) return;
        ['WebGLRenderer', 'CanvasRenderer', 'SystemRenderer'].forEach((name) => {
            const R = P[name];
            if (!R || !R.prototype || typeof R.prototype.render !== 'function' || R.prototype.__cezEspHook) return;
            const orig = R.prototype.render;
            R.prototype.render = function (displayObject) {
                if (displayObject && displayObject.children) {
                    let view = null;
                    try { view = this.view; } catch (e) { /* ignore */ }
                    if (view) {
                        const idx = _stages.findIndex((s) => s.stage === displayObject);
                        if (idx >= 0) _stages.splice(idx, 1);
                        _stages.unshift({ stage: displayObject, view: view });
                        if (_stages.length > 8) _stages.length = 8;
                        pixiCanvas = view;
                    }
                    if (!espReady) { espReady = true; updateUI(); }
                }
                return orig.apply(this, arguments);
            };
            R.prototype.__cezEspHook = true;
        });
    };

    const hasDesc = (node, Type) => {
        let found = false;
        (function walk(o) {
            if (found || !o) return;
            if (o instanceof Type) { found = true; return; }
            if (o.children) for (let i = 0; i < o.children.length; i++) walk(o.children[i]);
        })(node);
        return found;
    };

    // Lấy tên người chơi: node tên có thể chứa nhiều Text (nickname + gợi ý
    // như "spin to team"), nên chọn Text cỡ chữ lớn nhất — đó là bảng tên thật.
    const textOf = (node) => {
        let best = '', bestSize = -1;
        (function walk(o) {
            if (!o) return;
            if (o instanceof window.PIXI.Text && o.text && String(o.text).trim()) {
                const s = String(o.text);
                const fs = (o.style && o.style.fontSize ? Number(o.style.fontSize) : 0) || 0;
                if (fs > bestSize || (fs === bestSize && s.length > best.length)) { bestSize = fs; best = s; }
            }
            if (o.children) for (let i = 0; i < o.children.length; i++) walk(o.children[i]);
        })(node);
        return best;
    };

    const findGroups = (st) => {
        const P = window.PIXI;
        if (!P || !st || !st.children) return null;

        // Nhóm nhãn tên: container có >=3 con, mỗi con đều chứa Text không rỗng.
        let names = null;
        for (let i = 0; i < st.children.length; i++) {
            const c = st.children[i];
            if (!c || !c.children || c.children.length < 3) continue;
            let checked = Math.min(c.children.length, 6), withText = 0;
            for (let j = 0; j < checked; j++) if (textOf(c.children[j])) withText++;
            if (withText === checked) { names = c; break; }
        }
        if (!names) return null;

        // Nhóm thân: đúng gấp đôi số con, và mỗi cặp liền kề có chữ ký
        //   [chẵn] = có Graphics/Sprite (thân)   [lẻ] = container rỗng
        const want = names.children.length * 2;
        let body = null;
        for (let i = 0; i < st.children.length; i++) {
            const c = st.children[i];
            if (!c || !c.children || c.children.length !== want) continue;
            if (hasDesc(c.children[0], P.Text)) continue;
            let pairsChecked = 0, pairsOk = 0;
            for (let k = 0; k < Math.min(names.children.length, 6); k++) {
                const b0 = c.children[2 * k], b1 = c.children[2 * k + 1];
                if (!b0 || !b1) continue;
                pairsChecked++;
                const evenDrawn = hasDesc(b0, P.Sprite) || hasDesc(b0, P.Graphics);
                const oddDrawn = hasDesc(b1, P.Sprite) || hasDesc(b1, P.Graphics) || hasDesc(b1, P.Text);
                if (evenDrawn && !oddDrawn) pairsOk++;
            }
            if (pairsChecked >= 2 && pairsOk >= pairsChecked - 1) { body = c; break; }
        }
        return (names && body) ? { names, body } : null;
    };

    // Quét mọi stage đã thấy, chọn stage có nhiều người chơi nhất.
    const pickGroups = () => {
        let best = null, bestCount = 0;
        for (let i = 0; i < _stages.length; i++) {
            const entry = _stages[i];
            const g = findGroups(entry.stage);
            if (!g) continue;
            if (g.names.children.length > bestCount) {
                bestCount = g.names.children.length;
                best = { names: g.names, body: g.body, canvas: entry.view };
            }
        }
        return best;
    };

    const collectPlayers = () => {
        const now = Date.now();
        if (!_groups || now - _lastGroupScan > 1000 || !_groups.body.parent) {
            _groups = pickGroups();
            _lastGroupScan = now;
        }
        if (!_groups) return [];

        const { names, body } = _groups;
        const out = [];
        for (let k = 0; k < names.children.length; k++) {
            const b0 = body.children[2 * k];
            if (!b0) continue;
            let g;
            try { g = b0.getGlobalPosition(); } catch (e) { continue; }
            if (!g || g.x < -100000 || g.y < -100000) continue; // parked / chưa có vị trí
            out.push({
                name: textOf(names.children[k]) || '???',
                x: g.x,
                y: g.y,
                scale: (b0.scale ? b0.scale.x : 1) || 1
            });
        }
        return out;
    };

    const isInLobby = () => {
        const inp = document.querySelector('input[type=text]');
        if (inp && inp.offsetParent !== null) return true;
        const btns = document.getElementsByTagName('button');
        for (let i = 0; i < btns.length; i++) {
            const b = btns[i];
            if (b.offsetParent !== null && b.textContent.trim() === 'Play') return true;
        }
        return false;
    };

    const drawEsp = () => {
        requestAnimationFrame(drawEsp);
        try {
            const w = window.innerWidth, h = window.innerHeight;
            if (overlay.width !== w) overlay.width = w;
            if (overlay.height !== h) overlay.height = h;
            ovCtx.clearRect(0, 0, w, h);

            if (!config.espEnabled) return;
            if (isInLobby()) return; // chỉ vẽ khi đang trong trận

            const players = collectPlayers();
            if (players.length < 2) return;

            const gameCanvas = (_groups && _groups.canvas) || pixiCanvas;
            if (!gameCanvas) return;
            const rect = gameCanvas.getBoundingClientRect();
            if (!rect.width || !rect.height) return;

            // "Tôi" = người chơi gần tâm camera nhất (camera luôn bám nhân vật).
            let me = null, bestD = Infinity;
            for (let i = 0; i < players.length; i++) {
                const dx = players[i].x - rect.width / 2;
                const dy = players[i].y - rect.height / 2;
                const d = dx * dx + dy * dy;
                if (d < bestD) { bestD = d; me = players[i]; }
            }

            // Mục tiêu gần nhất được tô đậm — tương tự "current target" của evo.js.
            let target = null, bestT = Infinity;
            if (me) {
                for (let i = 0; i < players.length; i++) {
                    const p = players[i];
                    if (p === me) continue;
                    const dx = p.x - me.x, dy = p.y - me.y;
                    const d = dx * dx + dy * dy;
                    if (d < bestT) { bestT = d; target = p; }
                }
            }

            const vx0 = rect.left, vy0 = rect.top;
            const vx1 = rect.left + rect.width, vy1 = rect.top + rect.height;
            const vcx = rect.left + rect.width / 2, vcy = rect.top + rect.height / 2;
            const mx = me ? vx0 + me.x : vcx;
            const my = me ? vy0 + me.y : vcy;

            // Chấm xanh đánh dấu nhân vật mình.
            ovCtx.lineWidth = 2;
            ovCtx.strokeStyle = 'rgba(0,255,0,0.9)';
            ovCtx.beginPath();
            ovCtx.arc(mx, my, 10, 0, Math.PI * 2);
            ovCtx.stroke();

            // Mũi tên chỉ hướng đối thủ đang ngoài màn hình (kiểu offscreen indicator).
            const drawEdgeArrow = (sx, sy, color, label) => {
                let dx = sx - vcx, dy = sy - vcy;
                const len = Math.hypot(dx, dy) || 1;
                dx /= len; dy /= len;
                const m = 26;
                const hw = rect.width / 2 - m, hh = rect.height / 2 - m;
                const k = Math.min(Math.abs(hw / (dx || 1e-6)), Math.abs(hh / (dy || 1e-6)));
                const ex = vcx + dx * k, ey = vcy + dy * k;
                ovCtx.save();
                ovCtx.translate(ex, ey);
                ovCtx.rotate(Math.atan2(dy, dx));
                ovCtx.beginPath();
                ovCtx.moveTo(14, 0); ovCtx.lineTo(-8, -8); ovCtx.lineTo(-8, 8); ovCtx.closePath();
                ovCtx.fillStyle = color;
                ovCtx.fill();
                ovCtx.strokeStyle = 'rgba(0,0,0,0.7)';
                ovCtx.lineWidth = 1;
                ovCtx.stroke();
                ovCtx.restore();

                ovCtx.font = 'bold 12px Consolas, monospace';
                ovCtx.textAlign = 'center';
                ovCtx.textBaseline = 'middle';
                ovCtx.fillStyle = 'rgba(0,0,0,0.85)';
                ovCtx.fillText(label, ex - dx * 26 + 1, ey - dy * 26 + 1);
                ovCtx.fillStyle = color;
                ovCtx.fillText(label, ex - dx * 26, ey - dy * 26);
            };

            // Gộp danh sách đối thủ + sắp theo khoảng cách để mũi tên ngoài màn
            // hình chỉ hiện những mục tiêu gần nhất (tránh rối mép màn hình).
            const others = [];
            for (let i = 0; i < players.length; i++) {
                const p = players[i];
                if (p === me) continue;
                others.push({
                    p: p,
                    sx: vx0 + p.x,
                    sy: vy0 + p.y,
                    dist: me ? Math.hypot(p.x - me.x, p.y - me.y) : 0
                });
            }
            others.sort((a, b) => a.dist - b.dist);

            const MAX_OFFSCREEN = 8;
            let offscreenDrawn = 0;

            for (let i = 0; i < others.length; i++) {
                const p = others[i].p;
                const sx = others[i].sx;
                const sy = others[i].sy;
                const dist = Math.round(others[i].dist);
                const isTarget = p === target;
                const big = p.scale >= 2.5;
                const color = isTarget ? '#ffeb3b' : (big ? '#ff9800' : '#ff3355');

                // Ngoài khung nhìn -> chỉ vẽ mũi tên ở mép màn hình (tối đa MAX_OFFSCREEN).
                if (sx < vx0 || sx > vx1 || sy < vy0 || sy > vy1) {
                    if (isTarget || offscreenDrawn < MAX_OFFSCREEN) {
                        drawEdgeArrow(sx, sy, color, p.name + ' ' + dist + 'px');
                        offscreenDrawn++;
                    }
                    continue;
                }

                const half = 12 * p.scale;
                const cy = sy - half * 0.7;   // nhấc khung lên cho khớp thân nhân vật
                const left = sx - half, right = sx + half, top = cy - half, bottom = cy + half;

                // --- Snapline: đường nối từ mình tới mục tiêu ---
                ovCtx.beginPath();
                ovCtx.moveTo(mx, my);
                ovCtx.lineTo(sx, cy);
                if (isTarget) {
                    // Quầng sáng cho mục tiêu gần nhất trước khi vẽ nét chính.
                    ovCtx.strokeStyle = 'rgba(255,235,59,0.28)';
                    ovCtx.lineWidth = 5;
                    ovCtx.stroke();
                    ovCtx.beginPath();
                    ovCtx.moveTo(mx, my);
                    ovCtx.lineTo(sx, cy);
                }
                ovCtx.strokeStyle = isTarget ? '#ffeb3b' : 'rgba(255,255,255,0.38)';
                ovCtx.lineWidth = isTarget ? 2 : 1;
                ovCtx.stroke();

                // --- Khung 4 góc (corner brackets) để không che sprite ---
                const cornerLen = Math.max(6, Math.min(14, half * 0.55));
                ovCtx.strokeStyle = color;
                ovCtx.lineWidth = isTarget ? 3 : 2;
                ovCtx.beginPath();
                ovCtx.moveTo(left, top + cornerLen); ovCtx.lineTo(left, top); ovCtx.lineTo(left + cornerLen, top);
                ovCtx.moveTo(right - cornerLen, top); ovCtx.lineTo(right, top); ovCtx.lineTo(right, top + cornerLen);
                ovCtx.moveTo(right, bottom - cornerLen); ovCtx.lineTo(right, bottom); ovCtx.lineTo(right - cornerLen, bottom);
                ovCtx.moveTo(left + cornerLen, bottom); ovCtx.lineTo(left, bottom); ovCtx.lineTo(left, bottom - cornerLen);
                ovCtx.stroke();

                // --- Tên phía trên khung ---
                ovCtx.font = 'bold 14px Consolas, monospace';
                ovCtx.textAlign = 'center';
                ovCtx.textBaseline = 'bottom';
                const label = p.name + (big ? '  \u25B2BIG' : '');
                ovCtx.fillStyle = 'rgba(0,0,0,0.85)';
                ovCtx.fillText(label, sx + 1, top - 6 + 1);
                ovCtx.fillStyle = color;
                ovCtx.fillText(label, sx, top - 6);

                // --- Khoảng cách phía dưới khung ---
                ovCtx.font = 'bold 12px Consolas, monospace';
                ovCtx.textBaseline = 'top';
                const dstr = dist + ' px' + (isTarget ? ' \u25C0' : '');
                ovCtx.fillStyle = 'rgba(0,0,0,0.85)';
                ovCtx.fillText(dstr, sx + 1, bottom + 6 + 1);
                ovCtx.fillStyle = isTarget ? '#ffeb3b' : 'rgba(255,255,255,0.85)';
                ovCtx.fillText(dstr, sx, bottom + 6);
            }
        } catch (e) {
            // ESP lỗi không được làm sập phần spam
        }
    };

    // Liên tục thử móc PIXI cho tới khi game nạp xong (script là async/defer).
    setInterval(hookPixi, 400);
    hookPixi();
    requestAnimationFrame(drawEsp);

    // --- 5. Khởi động ---
    setTimeout(() => { if (config.autoCharge) send('mousedown'); }, 2000);

})();
