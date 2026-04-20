// js/nsfw-downloader.js

document.addEventListener('DOMContentLoaded', () => {
    const CONCURRENT_LIMIT = 1000000;
    const PROXY_URL = 'https://proxy.onii.pp.ua/cors?url=';
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

    const statusBar = document.getElementById('downloadStatusBar');
    const statusText = document.getElementById('statusText');
    const progressBar = document.getElementById('progressBar');
    const progressPercentage = document.getElementById('progressPercentage');

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

            if (!imageUrl) throw new Error("Image URL not found!");

            const imageResponse = await fetchWithRetry(imageUrl);
            const imageBlob = await imageResponse.blob();
            const fileName = imageUrl.split('/').pop();
            return { imageBlob, fileName };
        } catch (error) {
            if (retryCount > 0) return fetchImage(retryCount - 1);
            return null;
        }
    };

    const updateStatus = (text, progress) => {
        statusText.textContent = text;
        progressBar.style.width = `${progress}%`;
        progressPercentage.textContent = `${Math.round(progress)}%`;
    };

    const showStatusBar = () => {
        statusBar.classList.add('active');
        statusBar.classList.remove('hidden');
    };

    const hideStatusBar = () => {
        statusBar.classList.add('hidden');
        statusBar.classList.remove('active');
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
                    const progress = (completed / count) * 100;
                    updateStatus(`Downloaded ${completed}/${count} images`, progress);
                }
            }));
        }
        await Promise.all(promises);
        updateStatus('Generating ZIP file...', 100);
        return zip.generateAsync({ type: 'blob' });
    };

    downloadBtn.addEventListener('click', async () => {
        const imageCount = Math.max(parseInt(imageCountInput.value), 1) || 50;

        downloadBtn.disabled = true;
        loadingAnimation.classList.add('active');
        showStatusBar();
        updateStatus('Downloading images...', 0);

        try {
            const zipBlob = await downloadImages(imageCount);
            const fileName = `images-${generateRandomString(6)}.zip`;
            saveAs(zipBlob, fileName);
            updateStatus('Download Complete!', 100);
            setTimeout(hideStatusBar, 3000);
        } catch (error) {
            console.error("Download process error:", error);
            updateStatus('Error downloading images!', 0);
            setTimeout(hideStatusBar, 3000);
        } finally {
            downloadBtn.disabled = false;
            loadingAnimation.classList.remove('active');
        }
    });

    hideStatusBar();
});
