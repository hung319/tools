// js/sfw-downloader.js

document.addEventListener('DOMContentLoaded', () => {
    // --- Các hằng số và cài đặt ---
    const CONCURRENT_LIMIT = 10; // Giới hạn số lượt tải đồng thời để tránh quá tải API
    const PROXY_URL = 'https://api.allorigins.win/raw?url='; // Một proxy CORS khác để dự phòng
    
    const API_URLS = {
        'waifu.pics': 'https://api.waifu.pics/sfw/waifu',
        'konachan': 'https://konachan.net/post.json?tags=order:random+rating:safe&limit=1',
        'yande.re': 'https://yande.re/post.json?tags=order:random+rating:safe&limit=1'
    };

    // --- Lấy các phần tử DOM ---
    const downloadBtn = document.getElementById('downloadBtn');
    const imageCountInput = document.getElementById('imageCount');
    const apiSelector = document.getElementById('apiSelector');
    const loadingAnimation = document.getElementById('loadingAnimation');
    const statusDiv = document.getElementById('status');
    
    /**
     * Tạo một chuỗi ngẫu nhiên
     * @param {number} length - Độ dài của chuỗi
     * @returns {string} - Chuỗi ngẫu nhiên
     */
    const generateRandomString = (length) => {
        return Array.from({ length }, () => 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'.charAt(Math.floor(Math.random() * 62))).join('');
    };
    
    /**
     * Fetch URL với cơ chế thử lại
     * @param {string} url - URL cần fetch
     * @param {number} retries - Số lần thử lại
     * @returns {Promise<Response|null>}
     */
    const fetchWithRetry = async (url, retries = 3) => {
        for (let i = 0; i < retries; i++) {
            try {
                // Konachan và Yande.re cần proxy, Waifu.pics thì không
                const fetchUrl = url.includes('konachan') || url.includes('yande.re') ? `${PROXY_URL}${encodeURIComponent(url)}` : url;
                const response = await fetch(fetchUrl);
                if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
                return response;
            } catch (error) {
                console.warn(`Attempt ${i + 1} failed for ${url}. Retrying...`);
                if (i === retries - 1) return null;
            }
        }
    };
    
    /**
     * Lấy một ảnh từ API đã chọn
     * @returns {Promise<{imageBlob: Blob, fileName: string}|null>}
     */
    const fetchImage = async () => {
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
            const fileName = imageUrl.split('/').pop().replace(/\?.*$/, ''); // Xóa query params nếu có
            return { imageBlob, fileName };
        } catch (error) {
            console.error(error);
            return null;
        }
    };
    
    /**
     * Tải và nén các ảnh
     * @param {number} count - Số lượng ảnh cần tải
     * @returns {Promise<Blob>}
     */
    const downloadImages = async (count) => {
        const zip = new JSZip();
        let completed = 0;
        const promises = [];

        for (let i = 0; i < count; i++) {
            promises.push(
                fetchImage().then(result => {
                    if (result && result.imageBlob) {
                        zip.file(result.fileName, result.imageBlob);
                        completed++;
                        statusDiv.textContent = `Đã xử lý: ${completed}/${count} ảnh`;
                    }
                })
            );
        }
        await Promise.all(promises);
        statusDiv.textContent = 'Đang nén file ZIP...';
        return zip.generateAsync({ type: 'blob' });
    };

    // --- Gắn sự kiện cho nút Download ---
    downloadBtn.addEventListener('click', async () => {
        const imageCount = parseInt(imageCountInput.value) || 50;
        
        downloadBtn.disabled = true;
        loadingAnimation.classList.add('active');
        statusDiv.textContent = 'Đang khởi động...';
        statusDiv.style.display = 'block';

        try {
            const zipBlob = await downloadImages(imageCount);
            const fileName = `images-${generateRandomString(6)}.zip`;
            saveAs(zipBlob, fileName);
            statusDiv.textContent = 'Tải về hoàn tất!';
        } catch (error) {
            statusDiv.textContent = 'Lỗi! Vui lòng thử lại.';
            console.error("Error during download process:", error);
        } finally {
            downloadBtn.disabled = false;
            loadingAnimation.classList.remove('active');
        }
    });

    // Ẩn status ban đầu
    statusDiv.style.display = 'none';
});