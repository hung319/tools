// js/nsfw-downloader.js

document.addEventListener('DOMContentLoaded', () => {
    // Lưu ý: Logic date/time gốc đã được lược bỏ vì phần HTML hiển thị nó không còn trong template.
    // Logic tải file được giữ nguyên theo yêu cầu.

    const CONCURRENT_LIMIT = 1000000;
    const PROXY_URL = 'https://proxy.h4rs.io.vn/cors?url=';
    const API_URLS = {
        'waifu.pics': 'https://api.waifu.pics/nsfw/waifu',
        'konachan(questionable)': 'https://konachan.net/post.json?tags=order:random+rating:questionable&limit=1',
        'konachan(explicit)': 'https://konachan.net/post.json?tags=order:random+rating:explicit&limit=1',
        'yande.re(questionable)': 'https://yande.re/post.json?tags=order:random+rating:questionable&limit=1',
        'yande.re(explicit)': 'https://yande.re/post.json?tags=order:random+rating:explicit&limit=1'
    };
    
    const downloadBtn = document.getElementById('downloadBtn');
    const imageCountInput = document.getElementById('imageCount');
    const apiSelector = document.getElementById('apiSelector');
    const loadingAnimation = document.getElementById('loadingAnimation');
    const statusDiv = document.getElementById('status');

    const generateRandomString = (length) => Array.from({ length }, () => 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'.charAt(Math.floor(Math.random() * 62))).join('');

    const fetchWithRetry = async (url, retries = 3) => {
        try {
            const response = await fetch(`${PROXY_URL}${encodeURIComponent(url)}`);
            if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
            return response;
        } catch (error) {
            if (retries > 0) return fetchWithRetry(url, retries - 1);
            return null;
        }
    };

    const fetchImage = async (retryCount = 3) => {
        const selectedApi = document.getElementById('apiSelector').value;
        const apiUrl = API_URLS[selectedApi];
        try {
            const response = await fetchWithRetry(apiUrl);
            const data = await response.json();

            let imageUrl;
            if (selectedApi === 'waifu.pics') {
                imageUrl = data.url;
            } else {
                imageUrl = data[0]?.file_url;
            }

            if (!imageUrl) throw new Error("URL ảnh không xác định!");

            const imageResponse = await fetchWithRetry(imageUrl);
            const imageBlob = await imageResponse.blob();
            const fileName = imageUrl.split('/').pop();
            return { imageBlob, fileName };
        } catch (error) {
            if (retryCount > 0) return fetchImage(retryCount - 1);
            return null;
        }
    };

    const downloadImages = async (count) => {
        const zip = new JSZip();
        let completed = 0;
        const promises = [];
        for (let i = 0; i < count; i++) {
            if (promises.length >= CONCURRENT_LIMIT) {
                await Promise.all(promises);
                promises.length = 0;
            }
            promises.push(fetchImage().then(result => {
                if (result && result.imageBlob) {
                    zip.file(result.fileName, result.imageBlob);
                    completed++;
                    statusDiv.textContent = `Đã tải ${completed}/${count} ảnh`;
                }
            }));
        }
        await Promise.all(promises);
        statusDiv.textContent = 'Đang nén file ZIP...';
        return zip.generateAsync({ type: 'blob' });
    };

    downloadBtn.addEventListener('click', async () => {
        const imageCount = Math.max(parseInt(imageCountInput.value), 1) || 50;
        
        downloadBtn.disabled = true;
        loadingAnimation.classList.add('active');
        statusDiv.style.display = 'block';
        statusDiv.textContent = 'Đang tải ảnh...';

        try {
            const zipBlob = await downloadImages(imageCount);
            const fileName = `images-${generateRandomString(6)}.zip`;
            saveAs(zipBlob, fileName);
            statusDiv.textContent = 'Tải về hoàn tất!';
        } catch (error) {
            console.error("Download process error:", error);
            statusDiv.textContent = 'Lỗi khi tải ảnh!';
        } finally {
            downloadBtn.disabled = false;
            loadingAnimation.classList.remove('active');
        }
    });
    
    statusDiv.style.display = 'none';
});