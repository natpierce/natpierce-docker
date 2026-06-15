#!/bin/sh

_arch=$(uname -m)
case "$_arch" in
  x86_64)           export TARGET_ARCH="amd64" ;;
  aarch64|arm64)    export TARGET_ARCH="arm64" ;;
  armv7*)           export TARGET_ARCH="arm32" ;;
  *)                export TARGET_ARCH="unknown" ;;
esac

url_github="https://raw.githubusercontent.com/natpierce/update_resources/refs/heads/main/update_info.json"
url_gitee="https://raw.giteeusercontent.com/natpierce/update_resources/raw/main/update_info.json"
_json_data=""
_platform=""

export TARGET_VERSION=""
export TARGET_URL=""

[ "$TARGET_ARCH" = "unknown" ] && return 1

if [ "x${update}" = "xtrue" ]; then
    # 创建临时文件
    tmp_gh=$(mktemp)
    tmp_gt=$(mktemp)

    wget -qO- "$url_github" > "$tmp_gh" 2>/dev/null & pid_gh=$!
    wget -qO- "$url_gitee" > "$tmp_gt" 2>/dev/null & pid_gt=$!

    count=0
    while [ $count -lt 40 ]; do
        if grep -q "latestVersionName" "$tmp_gh" 2>/dev/null; then
            _json_data=$(cat "$tmp_gh"); _platform="github"; kill $pid_gt 2>/dev/null; break
        fi
        if grep -q "latestVersionName" "$tmp_gt" 2>/dev/null; then
            _json_data=$(cat "$tmp_gt"); _platform="gitee"; kill $pid_gh 2>/dev/null; break
        fi
        sleep 0.5
        count=$((count + 1))
    done
    rm -f "$tmp_gh" "$tmp_gt"

    if [ -n "$_json_data" ]; then
        export TARGET_VERSION=$(echo "$_json_data" | grep '"latestVersionName"' | sed 's/.*"latestVersionName": *"\([^"]*\)".*/\1/' | sed 's/v//g')
        
        export TARGET_URL=$(echo "$_json_data" | awk -v p="$_platform" -v a="$TARGET_ARCH" '
            $0 ~ "\""p"\"" {flag=1} 
            flag && $0 ~ "\""a"\"" {print $0; exit} 
            flag && $0 ~ "}" && c++>5 {flag=0}
        ' | sed 's/.*"'"$TARGET_ARCH"'": *"\([^"]*\)".*/\1/')
    fi

elif [ "x${update}" = "xfalse" ] && [ "x${customversion}" != "xnull" ] && [ -n "${customversion}" ]; then
    export TARGET_VERSION=$(echo "${customversion}" | sed 's/v//g')
fi