#!/bin/bash
# Script tu dong quet Endpoint va dang ky tai khoan WARP thuan Bash + OpenSSL

echo "[WARP-SCAN] Dang quet nhanh Endpoint toi uu bang Bash (Fresh Mode)..."
ips=("162.159.192" "162.159.193" "162.159.195" "162.159.204" "188.114.96" "188.114.97" "188.114.98" "188.114.99")
ports=(2408 500 864 880 894 934 1070 1180 3476 3581 4198 4500 5279 5956 7103 7152 7559 8319 8854 8886)
HEX_DATA="\x04\x1d\x69\xe6\x79\x22\x09\x9a\xa0\xb9\x3d\x1e\x7b\x30\x9e\xc5\x85\x1e\xe2\xa3\xd6\xbf\x82\xa8\xbb\x5b\xb0\x3e\xd4\x6f\xb2\x34\x65\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x77\xa4\xa8\xcd\x5d\x88\x3e\x66\x08\x8e\x5f\x70\xad\xb4\x2f\x8a"
DYNAMIC_ENDPOINT=""
best_latency=9999

for i in {1..12}; do
    rand_sub=${ips[$RANDOM % ${#ips[@]}]}
    rand_host=$((RANDOM % 254 + 1))
    rand_port=${ports[$RANDOM % ${#ports[@]}]}
    target_ip="${rand_sub}.${rand_host}"
    
    start_t=$(date +%s%3N)
    res=$(echo -ne "$HEX_DATA" | nc -w 1 -u "$target_ip" "$rand_port" 2>/dev/null | head -c 5 | xxd -p 2>/dev/null)
    end_t=$(date +%s%3N)
    
    if [[ "$res" == "cf00000000" ]]; then
        latency=$((end_t - start_t))
        if [ "$latency" -lt "$best_latency" ]; then
            best_latency=$latency
            DYNAMIC_ENDPOINT="${target_ip}:${rand_port}"
        fi
    fi
done

if [ -z "$DYNAMIC_ENDPOINT" ]; then
    echo "[WARP-SCAN] Khong scan kip endpoint hop le. Chuyen ve Endpoint mac dinh..."
    DYNAMIC_ENDPOINT="188.114.97.242:7559"
else
    echo "[WARP-SCAN] Da tim thay Endpoint ngon nhat: $DYNAMIC_ENDPOINT (Ping: ${best_latency}ms)"
fi

echo "[WARP-REG] Dang ky tai khoan thuc qua corsfix.com..."
openssl genpkey -algorithm X25519 -outform DER -out x25519_priv.der 2>/dev/null
PRIV_KEY=$(tail -c 32 x25519_priv.der | base64 | tr -d '\n\r ')

openssl pkey -inform DER -in x25519_priv.der -pubout -outform DER -out x25519_pub.der 2>/dev/null
PUB_KEY=$(tail -c 32 x25519_pub.der | base64 | tr -d '\n\r ')

rm -f x25519_priv.der x25519_pub.der
NOW_ISO=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")

REG_RESPONSE=$(curl -s 'https://proxy.corsfix.com/?https://api.cloudflareclient.com/v0a737/reg' \
  -H 'authority: proxy.corsfix.com' \
  -H 'accept: */*' \
  -H 'accept-language: vi-VN,vi;q=0.9' \
  -H 'content-type: application/json' \
  -H 'origin: https://lanrat.github.io' \
  -H 'referer: https://lanrat.github.io/' \
  -H 'user-agent: Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Mobile Safari/537.36' \
  --data-raw "{\"key\":\"$PUB_KEY\",\"install_id\":\"\",\"warp_enabled\":true,\"tos\":\"$NOW_ISO\",\"type\":\"Linux\",\"locale\":\"en_US\"}")

W_TOKEN=$(echo "$REG_RESPONSE" | jq -r '.token // empty' 2>/dev/null)
W_IPV4=$(echo "$REG_RESPONSE" | jq -r '.config.interface.addresses.v4 // empty' 2>/dev/null)

if [ -n "$W_TOKEN" ] && [ "$W_TOKEN" != "null" ]; then
    echo "[WARP-REG] -> TAO TAI KHOAN SUCCESS! Dang nap..."
    [[ "$W_IPV4" != *"/"* ]] && W_IPV4="${W_IPV4}/32"
    
    printf "[Interface]\nPrivateKey = %s\nAddress = %s\nDNS = 1.1.1.1\n\n[Peer]\nPublicKey = bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=\nEndpoint = %s\n\n[http]\nBindAddress = 127.0.0.1:4001\n" \
    "$PRIV_KEY" "$W_IPV4" "$DYNAMIC_ENDPOINT" > wireproxy.conf
else
    echo "[WARP-REG] -> Tao tai khoan that bai!"
    echo "[LOG PHAN HOI TU API] -> $REG_RESPONSE"
    exit 1
fi
