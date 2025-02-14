#!/system/bin/sh

PROXY_DIR="/data/adb/http_proxy"
HTTP_PROXY_SERVICE="http_proxy_service.sh"
COMMON_SERVICE_DIR="/data/adb/service.d"
KSU_SERVICE_DIR="/data/adb/ksu/service.d"

if [ ! -d "${PROXY_DIR}" ]; then
    exit 1
else
    rm -rf "${PROXY_DIR}"
fi

if [ -f "${COMMON_SERVICE_DIR}/${HTTP_PROXY_SERVICE}" ]; then
    rm -rf "${COMMON_SERVICE_DIR}/${HTTP_PROXY_SERVICE}"
fi

if [ -f "${KSU_SERVICE_DIR}/${HTTP_PROXY_SERVICE}" ]; then
    rm -rf "${KSU_SERVICE_DIR}/${HTTP_PROXY_SERVICE}"
fi
