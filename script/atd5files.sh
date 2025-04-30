#!/bin/bash

# 定义文件路径和下载链接
file1="/www/ystv7a.apk"
url1="https://github.com/FongMi/Release/raw/fongmi/apk/release/leanback-armeabi_v7a.apk"
file2="/www/mbv8a.apk"
url2="https://github.com/FongMi/Release/raw/fongmi/apk/release/mobile-arm64_v8a.apk"
file3="/www/ku9.apk"
url3="https://raw.githubusercontent.com/sowahsun/apk/refs/heads/main/ku9.apk"
file4="/www/tgyy.apk"
url4="https://raw.githubusercontent.com/sowahsun/apk/refs/heads/main/tgyy.apk"
file5="/www/okpro.apk"
url5="https://raw.githubusercontent.com/sowahsun/apk/refs/heads/main/okpro.apk"

# 检查文件是否存在并比较文件大小，根据条件下载
check_and_download() {
    local file=$1
    local url=$2
    local temp_file=$(mktemp)

    if [ -f "$file" ]; then
        echo "文件 $file 已存在，正在检查文件大小..."
        # 下载临时文件用于比较大小
        wget -q -O "$temp_file" "$url"
        if [ $? -ne 0 ]; then
            echo "下载临时文件失败，跳过检查。"
            rm -f "$temp_file"
            return
        fi

        local local_size=$(wc -c < "$file")
        local remote_size=$(wc -c < "$temp_file")

        echo "本地文件大小: $local_size"
        echo "远程文件大小: $remote_size"

        if [ -z "$local_size" ] || [ -z "$remote_size" ]; then
            echo "无法获取文件大小，跳过检查。"
            rm -f "$temp_file"
            return
        fi

        if [ "$local_size" -eq "$remote_size" ]; then
            echo "文件大小一致，无需下载。"
        else
            echo "文件大小不一致，正在下载并覆盖..."
            wget -O "$file" "$url"
            if [ $? -eq 0 ]; then
                echo "下载完成，文件已覆盖。"
            else
                echo "下载失败。"
            fi
        fi

        rm -f "$temp_file"
    else
        echo "文件 $file 不存在，正在下载..."
        wget -O "$file" "$url"
        if [ $? -eq 0 ]; then
            echo "下载完成。"
        else
            echo "下载失败。"
        fi
    fi
}

# 调用函数检查并下载文件
check_and_download "$file1" "$url1"
check_and_download "$file2" "$url2"
check_and_download "$file3" "$url3"
check_and_download "$file4" "$url4"
check_and_download "$file5" "$url5"