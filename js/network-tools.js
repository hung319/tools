// js/network-tools.js

document.addEventListener('DOMContentLoaded', () => {
    // --- Logic chuyển tab ---
    const tabBtns = document.querySelectorAll('.tab-btn');
    const tabContents = document.querySelectorAll('.tab-content');
    
    tabBtns.forEach(btn => {
        btn.addEventListener('click', () => {
            tabBtns.forEach(b => b.classList.remove('active'));
            btn.classList.add('active');
            
            const tabId = btn.getAttribute('data-tab');
            tabContents.forEach(content => {
                content.classList.remove('active');
                if (content.id === tabId) {
                    content.classList.add('active');
                }
            });
        });
    });

    // --- Helper Functions ---
    const showLoader = (loaderId) => document.getElementById(loaderId).style.display = 'block';
    const hideLoader = (loaderId) => document.getElementById(loaderId).style.display = 'none';
    const displayResults = (resultsId, data) => {
        const el = document.getElementById(resultsId);
        el.innerHTML = ''; // Clear previous results
        if (typeof data === 'string') {
            el.textContent = data;
        } else {
            el.textContent = JSON.stringify(data, null, 2);
        }
    };

    // --- Tool 1: My IP Info ---
    document.getElementById('fetch-my-ip').addEventListener('click', async () => {
        showLoader('my-ip-loader');
        try {
            const res = await fetch('http://ip-api.com/json/?fields=66846719');
            const data = await res.json();
            displayResults('my-ip-results', data);
        } catch (e) {
            displayResults('my-ip-results', 'Lỗi: Không thể lấy thông tin IP.');
        } finally {
            hideLoader('my-ip-loader');
        }
    });

    // --- Tool 2: IP/Host Lookup ---
    document.getElementById('lookup-btn').addEventListener('click', async () => {
        const input = document.getElementById('lookup-input').value.trim();
        if (!input) return;
        showLoader('lookup-loader');
        try {
            const res = await fetch(`http://ip-api.com/json/${input}?fields=66846719`);
            const data = await res.json();
            displayResults('lookup-results', data);
        } catch (e) {
            displayResults('lookup-results', `Lỗi khi tra cứu: ${input}`);
        } finally {
            hideLoader('lookup-loader');
        }
    });

    // --- Tool 3: WHOIS Lookup ---
    document.getElementById('whois-btn').addEventListener('click', async () => {
        const input = document.getElementById('whois-input').value.trim();
        if (!input) return;
        showLoader('whois-loader');
        // Sử dụng một proxy công cộng để gọi API WHOIS
        const apiUrl = `https://api.allorigins.win/raw?url=https://www.whoisxmlapi.com/whoisserver/WhoisService?domainName=${input}&outputFormat=JSON&apiKey=at_bA8qC1f6A7B8c9D0e1F2g3H4i5J6k7`; // Note: This is a placeholder key and API.
        try {
            // A real implementation would require a proper backend proxy due to API key security.
            // This is a best-effort client-side attempt.
            displayResults('whois-results', "Chức năng WHOIS cần một backend proxy chuyên dụng để hoạt động ổn định và bảo mật API key. Đây là bản demo giới hạn.");
        } catch (e) {
            displayResults('whois-results', `Lỗi khi tra cứu WHOIS: ${input}`);
        } finally {
            hideLoader('whois-loader');
        }
    });
    
    // --- Tool 4: Port Scanner ---
    document.getElementById('port-scan-btn').addEventListener('click', async () => {
        showLoader('port-scan-loader');
        displayResults('port-scan-results', "Scan port từ trình duyệt trực tiếp bị chặn vì lý do bảo mật. Chức năng này yêu cầu một backend chuyên dụng để thực thi.");
        hideLoader('port-scan-loader');
    });

    // --- Tool 5: DNS Lookup ---
    document.getElementById('dns-btn').addEventListener('click', async () => {
        const domain = document.getElementById('dns-input').value.trim();
        const type = document.getElementById('dns-type').value;
        if (!domain) return;
        showLoader('dns-loader');
        try {
            const res = await fetch(`https://cloudflare-dns.com/dns-query?name=${encodeURIComponent(domain)}&type=${type}`, {
                headers: { 'accept': 'application/dns-json' }
            });
            const data = await res.json();
            let htmlResult = '<table>';
            if (data.Answer) {
                data.Answer.forEach(ans => {
                    htmlResult += `<tr><td><strong>${ans.name}</strong></td><td>${ans.type}</td><td>${ans.data}</td><td>${ans.TTL}</td></tr>`;
                });
            } else {
                htmlResult += '<tr><td>Không tìm thấy bản ghi.</td></tr>';
            }
            htmlResult += '</table>';
            document.getElementById('dns-results').innerHTML = htmlResult;
        } catch (e) {
            displayResults('dns-results', `Lỗi khi tra cứu DNS: ${domain}`);
        } finally {
            hideLoader('dns-loader');
        }
    });
});