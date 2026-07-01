// js/img-downloader.js

document.addEventListener('DOMContentLoaded', () => {
    const PROXY_URL = 'https://proxy.onii.pp.ua/cors?url=';

    // ── API definitions ────────────────────────────────────────
    // Each api has:
    //   sfw() / nsfw()  → returns the raw fetch URL
    //   parse(data)     → extracts image URL from JSON response
    //   needProxy       → whether to route through CORS proxy (default true)

    const API_CONFIG = {
        // ── Anime APIs ──
        'waifu.im': {
            sfw: (tags) => {
                const p = new URLSearchParams({ PageSize: '1', IsNsfw: 'False' });
                tags.forEach(t => p.append('IncludedTags', t));
                return `https://api.waifu.im/images?${p}`;
            },
            nsfw: (tags) => {
                const p = new URLSearchParams({ PageSize: '1', IsNsfw: 'True' });
                tags.forEach(t => p.append('IncludedTags', t));
                return `https://api.waifu.im/images?${p}`;
            },
            parse: (d) => d.items?.[0]?.url || null,
        },

        'nekosapi': {
            sfw: () => 'https://api.nekosapi.com/v4/images/random?nsfw=false&gif=false',
            nsfw: () => 'https://api.nekosapi.com/v4/images/random?nsfw=true&gif=false',
            parse: (d) => d[0]?.url || null,
        },

        'nekosia': {
            sfw: () => 'https://api.nekosia.cat/api/v1/images/catgirl',
            // Nekosia is SFW-only
            nsfw: null,
            parse: (d) => d.image?.original?.url || null,
        },

        // ── Booru APIs ──
        'konachan': {
            sfw: () => 'https://konachan.net/post.json?tags=order:random+rating:safe&limit=1',
            nsfw: () => 'https://konachan.net/post.json?tags=order:random+rating:questionable+OR+rating:explicit&limit=1',
            parse: (d) => d[0]?.file_url || null,
        },

        'yande.re': {
            sfw: () => 'https://yande.re/post.json?tags=order:random+rating:safe&limit=1',
            nsfw: () => 'https://yande.re/post.json?tags=order:random+rating:questionable+OR+rating:explicit&limit=1',
            parse: (d) => d[0]?.file_url || null,
        },

        // ── Random image APIs ──
        'pic.re': {
            sfw: () => 'https://pic.re/image',
            nsfw: null,
            parse: null, // pic.re returns raw image, no JSON
            returnsRawImage: true,
        },
    };

    // ── State ──────────────────────────────────────────────────
    let isNsfw = false;
    let selectedTags = ['waifu'];

    // ── DOM ────────────────────────────────────────────────────
    const downloadBtn = document.getElementById('downloadBtn');
    const imageCountInput = document.getElementById('imageCount');
    const apiSelector = document.getElementById('apiSelector');
    const statusBar = document.getElementById('downloadStatusBar');
    const statusText = document.getElementById('statusText');
    const progressBar = document.getElementById('progressBar');
    const progressPercentage = document.getElementById('progressPercentage');
    const modeSfw = document.getElementById('modeSfw');
    const modeNsfw = document.getElementById('modeNsfw');
    const nsfwWarning = document.getElementById('nsfwWarning');
    const tagGroup = document.getElementById('tagGroup');
    const tagSelector = document.getElementById('tagSelector');
    const sourceInfo = document.getElementById('sourceInfo');

    // ── Source metadata ────────────────────────────────────────
    const SOURCE_META = {
        'waifu.im':   { tagSupport: true,  nsfwSupport: true,  info: 'Anime illustrations. Tags supported.' },
        'nekosapi':   { tagSupport: false, nsfwSupport: true,  info: '40k+ anime images. SFW/NSFW toggle.' },
        'nekosia':    { tagSupport: false, nsfwSupport: false, info: 'SFW-only catgirl images.' },
        'konachan':   { tagSupport: false, nsfwSupport: true,  info: 'Booru. SFW/NSFW via rating tags.' },
        'yande.re':   { tagSupport: false, nsfwSupport: true,  info: 'Booru. SFW/NSFW via rating tags.' },
        'pic.re':     { tagSupport: false, nsfwSupport: false, info: 'Random anime image. SFW-only. No API key needed.' },
    };

    // ── Helpers ────────────────────────────────────────────────
    const generateRandomString = (len) =>
        Array.from({ length: len }, () =>
            'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
                .charAt(Math.floor(Math.random() * 62))
        ).join('');

    const sleep = (ms) => new Promise(r => setTimeout(r, ms));

    const fetchWithRetry = async (url, retries = 3, useProxy = true) => {
        const finalUrl = useProxy ? `${PROXY_URL}${encodeURIComponent(url)}` : url;
        for (let i = 0; i <= retries; i++) {
            try {
                const res = await fetch(finalUrl);
                if (!res.ok) throw new Error(`HTTP ${res.status}`);
                return res;
            } catch (e) {
                if (i === retries) return null;
                await sleep(500 * (i + 1));
            }
        }
        return null;
    };

    const updateStatus = (text, pct) => {
        statusText.textContent = text;
        progressBar.style.width = `${pct}%`;
        progressPercentage.textContent = `${Math.round(pct)}%`;
    };

    const showStatusBar = () => {
        statusBar.classList.add('active');
        statusBar.classList.remove('hidden');
    };

    const hideStatusBar = () => {
        statusBar.classList.remove('active');
        statusBar.classList.add('hidden');
    };

    // ── Fetch a single image ───────────────────────────────────
    const fetchImage = async (retryCount = 3) => {
        const source = apiSelector.value;
        const api = API_CONFIG[source];
        if (!api) return null;

        const mode = isNsfw ? 'nsfw' : 'sfw';
        const urlBuilder = api[mode];

        // Source doesn't support this mode
        if (!urlBuilder) return null;

        const apiUrl = source === 'waifu.im' ? urlBuilder(selectedTags) : urlBuilder();
        const useProxy = api.returnsRawImage ? false : true;

        try {
            if (api.returnsRawImage) {
                // pic.re returns a raw image — fetch directly (CORS-free)
                const res = await fetchWithRetry(apiUrl, retryCount, false);
                if (!res) throw new Error('Image fetch failed');
                const blob = await res.blob();
                const ext = blob.type?.includes('png') ? 'png' : 'jpg';
                return { imageBlob: blob, fileName: `${generateRandomString(8)}.${ext}` };
            }

            // JSON APIs
            const res = await fetchWithRetry(apiUrl, retryCount, useProxy);
            if (!res) throw new Error('API request failed');

            const data = await res.json();
            const imageUrl = api.parse(data);
            if (!imageUrl) throw new Error('No image URL in response');

            const imgRes = await fetchWithRetry(imageUrl, retryCount, true);
            if (!imgRes) throw new Error('Image download failed');

            const imageBlob = await imgRes.blob();
            const fileName = imageUrl.split('/').pop().split('?')[0] || `${generateRandomString(8)}.jpg`;
            return { imageBlob, fileName };
        } catch (err) {
            if (retryCount > 0) return fetchImage(retryCount - 1);
            console.error('fetchImage error:', err);
            return null;
        }
    };

    // ── Download all images ────────────────────────────────────
    const downloadAll = async (count) => {
        const zip = new JSZip();
        let done = 0;
        const batchSize = 5;

        for (let i = 0; i < count; i += batchSize) {
            const batch = [];
            const n = Math.min(batchSize, count - i);

            for (let j = 0; j < n; j++) {
                batch.push(
                    fetchImage().then(result => {
                        if (result?.imageBlob) {
                            zip.file(result.fileName, result.imageBlob);
                            done++;
                            updateStatus(`Downloaded ${done}/${count}`, (done / count) * 100);
                        }
                    })
                );
            }

            await Promise.all(batch);
        }

        updateStatus('Generating ZIP...', 100);
        return zip.generateAsync({ type: 'blob' });
    };

    // ── Mode toggle ────────────────────────────────────────────
    const setMode = (nsfw) => {
        isNsfw = nsfw;
        modeSfw.classList.toggle('active', !nsfw);
        modeNsfw.classList.toggle('active', nsfw);
        nsfwWarning.classList.toggle('visible', nsfw);
        updateSourceInfo();
    };

    modeSfw.addEventListener('click', () => setMode(false));
    modeNsfw.addEventListener('click', () => setMode(true));

    // ── Tag selection ──────────────────────────────────────────
    tagSelector.addEventListener('click', (e) => {
        const btn = e.target.closest('.tag-btn');
        if (!btn) return;

        const tag = btn.dataset.tag;
        if (btn.classList.contains('active')) {
            if (selectedTags.length <= 1) return;
            selectedTags = selectedTags.filter(t => t !== tag);
            btn.classList.remove('active');
        } else {
            selectedTags.push(tag);
            btn.classList.add('active');
        }
    });

    // ── Source info & tag visibility ───────────────────────────
    const updateSourceInfo = () => {
        const source = apiSelector.value;
        const meta = SOURCE_META[source];
        if (!meta) return;

        sourceInfo.textContent = meta.info;

        // Show tags only for sources that support them
        tagGroup.style.display = meta.tagSupport ? '' : 'none';

        // Disable NSFW button if source doesn't support it
        if (!meta.nsfwSupport) {
            modeNsfw.disabled = true;
            modeNsfw.style.opacity = '0.4';
            modeNsfw.style.cursor = 'not-allowed';
            if (isNsfw) setMode(false); // force SFW if switching to SFW-only source
        } else {
            modeNsfw.disabled = false;
            modeNsfw.style.opacity = '1';
            modeNsfw.style.cursor = 'pointer';
        }
    };

    apiSelector.addEventListener('change', updateSourceInfo);

    // ── Download button ────────────────────────────────────────
    downloadBtn.addEventListener('click', async () => {
        const count = Math.max(parseInt(imageCountInput.value) || 20, 1);

        // Check if current mode is supported
        const api = API_CONFIG[apiSelector.value];
        const mode = isNsfw ? 'nsfw' : 'sfw';
        if (!api[mode]) {
            updateStatus(`${apiSelector.value} does not support ${mode.toUpperCase()} mode`, 0);
            showStatusBar();
            setTimeout(hideStatusBar, 3000);
            return;
        }

        downloadBtn.disabled = true;
        downloadBtn.textContent = 'DOWNLOADING...';
        showStatusBar();
        updateStatus('Downloading images...', 0);

        try {
            const zipBlob = await downloadAll(count);
            saveAs(zipBlob, `images-${generateRandomString(6)}.zip`);
            updateStatus('Complete!', 100);
            setTimeout(hideStatusBar, 3000);
        } catch (err) {
            console.error('Download error:', err);
            updateStatus('Error!', 0);
            setTimeout(hideStatusBar, 3000);
        } finally {
            downloadBtn.disabled = false;
            downloadBtn.textContent = 'DOWNLOAD & ZIP';
        }
    });

    // ── Init ───────────────────────────────────────────────────
    hideStatusBar();
    updateSourceInfo();
});
