#!/usr/bin/env bash
## 编辑docker-compose.yml文件添加 - CUSTOM_SHELL_FILE=https://raw.githubusercontent.com/mixool/jd_sku/main/jd_diy.sh
### CUSTOM_SHELL_FILE for https://gitee.com/lxk0301/jd_docker/tree/master/docker
#### 由于更新可能引入未知BUG,建议复制脚本内容至GIST使用
# https://raw.githubusercontent.com/monk-coder/dust/dust/shell_script_mod.sh
# https://raw.githubusercontent.com/mixool/jd_sku/main/jd_diy.sh

function owner(){
    cd / && apk update && apk upgrade && cd / && apk add --no-cache screen bash make wget vim curl python3-dev py3-pip py3-cryptography htop
    cd / && pip3 install wheel telethon pysocks httpx requests Cython
	wget -O https://raw.githubusercontent.com/work4933/jd/main/test_jd_necklace.js /scripts/owner_jd_necklace.js 
    git clone https://github.com/shufflewzc/faker2.git /shufflewzc
}

function shufflewzc(){
    rm -rf /scripts/shufflewzc_*
    for jsname in $(find /shufflewzc -name "*.js" | grep -vE "\/backup\/"| grep -vE "Opencard"); do cp ${jsname} /scripts/shufflewzc_${jsname##*/}; done
}

function diycron(){
    for jsname in /scripts/owner_*.js /scripts/shufflewzc_*.js; do
        jsnamecron="$(cat $jsname | grep -oE "/?/?cron \".*\"" | cut -d\" -f2)"
        test -z "$jsnamecron" || echo "$jsnamecron node $jsname >> /scripts/logs/$(echo $jsname | cut -d/ -f3 | cut -d. -f1).log 2>&1" >> /scripts/docker/merged_list_file.sh
    done
    
    ln -sf /usr/local/bin/docker_entrypoint.sh /usr/local/bin/docker_entrypoint_mix.sh
    echo "47 */3 * * * docker_entrypoint_mix.sh >> /scripts/logs/default_task_mix.log 2>&1" >> /scripts/docker/merged_list_file.sh
}

function main(){
    # 首次运行时拷贝docker目录下文件
    [[ ! -d /jd_sku ]] && mkdir /jd_sku && cp -rf /scripts/docker/* /jd_sku
    # DIY脚本
    a_jsnum=$(ls -l /scripts | grep -oE "^-.*js$" | wc -l)
    a_jsname=$(ls -l /scripts | grep -oE "^-.*js$" | grep -oE "[^ ]*js$")
	shufflewzc
    owner
    b_jsnum=$(ls -l /scripts | grep -oE "^-.*js$" | wc -l)
    b_jsname=$(ls -l /scripts | grep -oE "^-.*js$" | grep -oE "[^ ]*js$")
    # DIY任务
    diycron
    # DIY脚本更新TG通知
    info_more=$(echo $a_jsname  $b_jsname | tr " " "\n" | sort | uniq -c | grep -oE "1 .*$" | grep -oE "[^ ]*js$" | tr "\n" " ")
    [[ "$a_jsnum" == "0" || "$a_jsnum" == "$b_jsnum" ]] || curl -sX POST "https://api.telegram.org/bot$TG_BOT_TOKEN/sendMessage" -d "chat_id=$TG_USER_ID&text=DIY脚本更新完成：$a_jsnum $b_jsnum $info_more" >/dev/null
    # LXK脚本更新TG通知
    lxktext="$(diff /jd_sku/crontab_list.sh /scripts/docker/crontab_list.sh | grep -E "^[+-]{1}[^+-]+" | grep -oE "node.*\.js" | cut -d/ -f3 | tr "\n" " ")"
    test -z "$lxktext" || curl -sX POST "https://api.telegram.org/bot$TG_BOT_TOKEN/sendMessage" -d "chat_id=$TG_USER_ID&text=LXK脚本更新完成：$(cat /jd_sku/crontab_list.sh | grep -vE "^#" | wc -l) $(cat /scripts/docker/crontab_list.sh | grep -vE "^#" | wc -l) $lxktext" >/dev/null
    # 拷贝docker目录下文件供下次更新时对比
    cp -rf /scripts/docker/* /jd_sku
	cd /scripts && npm install && cnpm install -g typescript ts-node https http stream zlib vm png-js axios date-fns ts-md5 dotenv crypto-js
	cd /scripts && npm install --save got cnpm tough-cookie qiniu ws bufferutil utf-8-validate png-js
	cd /scripts && apk add --no-cache build-base g++ cairo-dev pango-dev giflib-dev && npm install canvas --build-from-source

}

main
