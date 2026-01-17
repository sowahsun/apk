#!/bin/bash
# ==============================================================================
# 脚本名称: atd5files.sh (全注释+重试加强版)
# 存放位置: /root/atd5files.sh
# 适用环境: iStoreOS / OpenWrt (1000M 宽带环境)
# 核心逻辑: 先下到临时目录 -> 比对字节大小 -> 有变动则覆盖 -> 失败自动重试
# ==============================================================================

# --- 【第一部分：维护下载列表】 ---
# 格式: "本地目标路径|远程下载直链"
file_list=(
    # 1. 影视 TV版：指定安卓5专用 4.0.7 v7a 长期稳定版 (使用 isteed 镜像加速)
    "/www/ystv7a.apk|https://cors.isteed.cc/https://raw.githubusercontent.com/sowahsun/apk/refs/heads/main/Fongmi_TV_4.0.7_v7a.apk"
    
    # 2. 影视 手机版：最新手机端 arm64_v8a (使用 isteed 镜像加速)
    "/www/mbv8a.apk|https://cors.isteed.cc/https://github.com/xixu-me/fongmi-tv-actions-builder/releases/latest/download/mobile-arm64_v8a.apk"
    
    # 3. OK影视 Pro：推荐使用的 TV版 v7a 架构 (GitLab 稳定源)
    "/www/okpro.apk|https://gitlab.com/ygcmseven/app/-/raw/main/apk/leanback-pro.apk"
    
    # 4. 酷9：TV端经典应用 (GitHub 直连)
    "/www/ku9.apk|https://raw.githubusercontent.com/sowahsun/apk/refs/heads/main/ku9.apk"
    
    # 5. 天光云影：常用影视备份 (GitHub 直连)
    "/www/tgyy.apk|https://raw.githubusercontent.com/sowahsun/apk/refs/heads/main/tgyy.apk"
)

# --- 【第二部分：核心下载与比对函数】 ---
process_update() {
    local file=$1              # 本地存储路径
    local url=$2               # 远程链接
    local temp_file=$(mktemp)  # 创建随机命名的临时文件
    local max_retries=3        # 网络抖动时最大重试 3 次
    local retry_count=0        # 当前重试计数
    local success=false        # 下载成功标志位

    # 【1. 下载循环逻辑：带自动重试】
    while [ $retry_count -lt $max_retries ]; do
        # -T 30: 30秒超时 | -q: 静默不显示进度 | -O: 输出到临时文件
        wget -T 30 -q -O "$temp_file" "$url"
        
        # 检查 wget 退出码 ($? -eq 0) 且 文件大小不为 0 (-s)
        if [ $? -eq 0 ] && [ -s "$temp_file" ]; then
            success=true
            break # 下载成功，跳出循环
        else
            retry_count=$((retry_count + 1))
            if [ $retry_count -lt $max_retries ]; then
                echo "⚠️ [网络抖动] $file 下载失败，正在进行第 $retry_count 次重试..."
                sleep 3 # 停顿 3 秒后再试，给加速镜像一点反应时间
            fi
        fi
    done

    # 【2. 彻底失败检查】
    if [ "$success" = false ]; then
        echo "❌ [严重错误] 历经 ${max_retries} 次尝试均无法下载: $file"
        rm -f "$temp_file" # 清理可能残留的空文件
        return
    fi

    # 【3. 比对更新逻辑】
    if [ -f "$file" ]; then
        # wc -c 命令精确获取物理字节数，比对是否一致
        local local_size=$(wc -c < "$file")
        local remote_size=$(wc -c < "$temp_file")

        if [ "$local_size" -eq "$remote_size" ]; then
            # 大小完全一致，说明文件没有任何改动
            echo "✅ [保持] 文件未更新，跳过: $file"
            rm -f "$temp_file"
        else
            # 大小不同，说明远程有新版本
            echo "⬇️ [同步] 发现新版本 ($remote_size 字节)，正在覆盖: $file"
            mv -f "$temp_file" "$file" # 强行覆盖
            chmod 644 "$file"          # 设置标准权限
        fi
    else
        # 本地完全没有该文件，直接完成首次下载
        echo "🆕 [安装] 首次同步成功，已下载到: $file"
        mv -f "$temp_file" "$file"
        chmod 644 "$file"
    fi
}

# --- 【第三部分：主程序执行入口】 ---
echo "------------------------------------------------------------"
echo "🚀 任务启动: $(date "+%Y-%m-%d %H:%M:%S")"
echo "------------------------------------------------------------"

# 循环读取配置列表中的每一对路径与链接
for item in "${file_list[@]}"; do
    # 使用通配符分割字符串：以 | 为界
    local_path="${item%%|*}"  # 获取左边部分
    download_url="${item##*|}" # 获取右边部分
    
    # 调用上面的函数处理
    process_update "$local_path" "$download_url"
done

echo "------------------------------------------------------------"
echo "✨ 所有任务已处理完毕！"
echo "------------------------------------------------------------"
EOF