// js/sfw-downloader.js

document.addEventListener('DOMContentLoaded', () => {
    const CONCURRENT_LIMIT = 1000000;
    
    // Sử dụng proxy gốc của bạn
    const PROXY_URL = 'https://proxy.h4rs.io.vn/cors?url=';
    const API_URLS = {
        'waifu.pics': 'https://waifu.pics/api/sfw/waifu',
        'konachan': 'https://konachan.net/post.json?tags=order:random+rating:safe&limit=1',
        'yande.re': 'https://yande.re/post.json?tags=order:random+rating:safe&limit=1'
    };
    
    // Lấy các phần tử DOM
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
        const selectedApi = apiSelector.value;
        const apiUrl = API_URLS[selectedApi];
        try {
            const response = await fetchWithRetry(apiUrl);
            if (!response) throw new Error("API request failed.");
            
            const data = await response.json();
            const imageUrl = selectedApi === 'waifu.pics' ? data.url : data[0].file_url;
            
            const imageResponse = await fetchWithRetry(imageUrl);
            if (!imageResponse) throw new Error("Image download failed.");

            const imageBlob = await imageResponse.blob();
            const fileName = imageUrl.split('/').pop();
            return { imageBlob, fileName };
        } catch (error) {
            console.error("Fetch image error:", error);
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
        const imageCount = parseInt(imageCountInput.value) || 50;
        
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
    
    // Ẩn status ban đầu
    statusDiv.style.display = 'none';
});