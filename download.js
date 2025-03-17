const PROXY_URL = 'https://proxy.h4rs.io.vn/cors?url=';
const API_URLS = {
    'waifu.pics': 'https://waifu.pics/api/nsfw/waifu',
    'konachan(questionable)': 'https://konachan.net/post.json?tags=order:random+rating:questionable&limit=1',
    'konachan(explicit)': 'https://konachan.net/post.json?tags=order:random+rating:explicit&limit=1',
    'yande.re(questionable)': 'https://yande.re/post.json?tags=order:random+rating:questionable&limit=1',
    'yande.re(explicit)': 'https://yande.re/post.json?tags=order:random+rating:explicit&limit=1'
};

async function fetchImage() {
    const selectedApi = document.getElementById('apiSelector').value;
    const apiUrl = API_URLS[selectedApi];

    try {
        const response = await fetch(`${PROXY_URL}${encodeURIComponent(apiUrl)}`);
        const data = await response.json();
        return selectedApi === 'waifu.pics' ? data.url : data[0]?.file_url;
    } catch (error) {
        return null;
    }
}

async function downloadImages(count) {
    const zip = new JSZip();
    const status = document.getElementById('status');
    let completed = 0;

    for (let i = 0; i < count; i++) {
        const imageUrl = await fetchImage();
        if (imageUrl) {
            const response = await fetch(imageUrl);
            const blob = await response.blob();
            zip.file(`image${i + 1}.jpg`, blob);
            completed++;
            status.textContent = `Đã tải ${completed}/${count} ảnh`;
        }
    }

    const zipBlob = await zip.generateAsync({ type: 'blob' });
    saveAs(zipBlob, `images.zip`);
    status.textContent = 'Tải về hoàn tất!';
}

document.getElementById('downloadBtn').addEventListener('click', async () => {
    const imageCount = Math.max(parseInt(document.getElementById('imageCount').value), 1);
    document.getElementById('status').textContent = 'Đang tải ảnh...';
    await downloadImages(imageCount);
});