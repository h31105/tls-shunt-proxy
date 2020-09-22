#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

echo "info: Checking the current version ."
[[ -f /usr/local/bin/tls-shunt-proxy ]] && current_tsp_version="$(/usr/local/bin/tls-shunt-proxy --help 2>&1 | awk 'NR==1{gsub(/"/,"");print $3}')"
[[ -z ${current_tsp_version} ]] && echo 'info: tls-shunt-proxy is not installed .'

echo "info: Checking the release version ."
release_tsp_version=$(curl -L -s https://api.github.com/repos/liberal-boy/tls-shunt-proxy/releases/latest | grep "tag_name" | head -1 | awk -F '"' '{print $4}')
[[ -z ${release_tsp_version} ]] && echo 'error: Failed to get release list, please check your network .' && exit 2

echo "$release_tsp_version" >$version_tsp_cmp
echo "$current_tsp_version" >>$version_tsp_cmp
bc_tsp_version="0.6.2"

if [[ "$current_tsp_version" < "$(sort -rV $version_tsp_cmp | head -1)" ]]; then
    [[ "$current_tsp_version" < "$bc_tsp_version" ]] && read -rp "warn: Found the latest release of tls-shunt-proxy $release_tsp_version with a BREAKING CHANGE, upgrade now (Y/N) [N]?" upgrade_confirm
    [[ -z ${upgrade_confirm} ]] && upgrade_confirm="no"
    [[ "$current_tsp_version" >= "$bc_tsp_version" && -z ${current_tsp_version} ]] && upgrade_confirm="yes"
    case $upgrade_confirm in
    [yY][eE][sS] | [yY])
        echo "info: Prepare to install the latest version ."
        ;;
    *) 
        exit 0
        ;;
    esac
else
    echo "info: No new version. The current version of tls-shunt-proxy is $current_tsp_version ."
    exit 0
fi
    
VSRC_ROOT='/tmp/tls-shunt-proxy'
DOWNLOAD_PATH='/tmp/tls-shunt-proxy/tls-shunt-proxy.zip'

API_URL="https://api.github.com/repos/liberal-boy/tls-shunt-proxy/releases/latest"
DOWNLOAD_URL="$(curl "${PROXY}" -H "Accept: application/json" -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:74.0) Gecko/20100101 Firefox/74.0" -s "${API_URL}" --connect-timeout 10| grep 'browser_download_url' | cut -d\" -f4)"

echo "${DOWNLOAD_URL}"

mkdir -p "${VSRC_ROOT}"
curl -L -H "Cache-Control: no-cache" -o "${DOWNLOAD_PATH}" "${DOWNLOAD_URL}"
unzip -o -d /usr/local/bin/ "${DOWNLOAD_PATH}"
chmod +x /usr/local/bin/tls-shunt-proxy

useradd tls-shunt-proxy -s /usr/sbin/nologin

mkdir -p '/etc/systemd/system'
curl -L -H "Cache-Control: no-cache" -o '/etc/systemd/system/tls-shunt-proxy.service' 'https://raw.githubusercontent.com/liberal-boy/tls-shunt-proxy/master/dist/tls-shunt-proxy.service'

if [ ! -f "/etc/tls-shunt-proxy/config.yaml" ]; then
  mkdir -p '/etc/tls-shunt-proxy'
  curl -L -H "Cache-Control: no-cache" -o '/etc/tls-shunt-proxy/config.yaml' 'https://raw.githubusercontent.com/liberal-boy/tls-shunt-proxy/master/config.simple.yaml'
fi

mkdir -p '/etc/ssl/tls-shunt-proxy'
chown -R tls-shunt-proxy:tls-shunt-proxy /etc/ssl/tls-shunt-proxy

rm -r "${VSRC_ROOT}"
