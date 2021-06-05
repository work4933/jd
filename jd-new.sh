#!/usr/bin/env bash
## 编辑docker-compose.yml文件添加 - CUSTOM_SHELL_FILE=https://raw.githubusercontent.com/mixool/jd_sku/main/jd_diy.sh
### CUSTOM_SHELL_FILE for https://gitee.com/lxk0301/jd_docker/tree/master/docker
#### DIY脚本仅供参考,由于更新可能引入未知BUG,建议Fork后使用自己项目的raw地址

function monkcoder(){
    # https://github.com/monk-coder/dust
    rm -rf /monkcoder /scripts/monkcoder_*
    git clone https://github.com/mengdie101/Myactions.git /monkcoder
    for jsname in $(find /monkcoder/dust -name "*.js" | grep -vE "\/backup\/"); do cp ${jsname} /scripts/dust_${jsname##*/}; done
}

function whyour(){
    # https://github.com/whyour/hundun/tree/master/quanx
    rm -rf /whyour /scripts/whyour_*
    git clone https://github.com/whyour/hundun.git /whyour
    for jsname in jdzz.js jx_nc.js jx_factory.js jx_factory_component.js ddxw.js dd_factory.js jd_zjd_tuan.js; do cp -rf /whyour/quanx/$jsname /scripts/whyour_$jsname; done
}

function nianyuguai(){
    # https://github.com/nianyuguai/longzhuzhu.git
    rm -rf /longzhuzhu /scripts/longzhuzhu_*
    git clone -b main https://github.com/nianyuguai/longzhuzhu.git /longzhuzhu
    for jsname in $(ls /longzhuzhu/qx | grep -oE ".*\js$"); do cp -rf /longzhuzhu/qx/$jsname /scripts/longzhuzhu_$jsname; done
    for jsonname in $(ls /longzhuzhu/qx | grep -oE ".*\json$"); do cp -rf /longzhuzhu/qx/$jsonname /scripts/$jsonname; done
}

function zcy01(){
    # https://raw.githubusercontent.com/ZCY01/daily_scripts/main/jd/jd_try.js
    wget -qO /scripts/zcy01_jd_try.js https://raw.githubusercontent.com/ZCY01/daily_scripts/main/jd/jd_try.js
    echo "30 10 * * * node /scripts/zcy01_jd_try.js >> /scripts/logs/zcy01_jd_try.js.log 2>&1" >> /scripts/docker/merged_list_file.sh
}

function wenmoux(){
    # https://github.com/monk-coder/dust
    rm -rf /wenmoux /scripts/wenmoux_*
    git clone https://github.com/Wenmoux/scripts.git /wenmoux
    for jsname in $(find /wenmoux -name "*.js" | grep -vE "\/backup\/"); do cp ${jsname} /scripts/wenmoux_${jsname##*/}; done
}

function diycron(){
    # monkcoder whyour nianyuguai 定时任务
    for jsname in /scripts/dust_*.js /scripts/wenmoux_*.js /scripts/whyour_*.js /scripts/longzhuzhu_*.js; do
        jsnamecron="$(cat $jsname | grep -oE "/?/?cron \".*\"" | cut -d\" -f2)"
        test -z "$jsnamecron" || echo "$jsnamecron node $jsname >> /scripts/logs/$(echo $jsname | cut -d/ -f3).log 2>&1" >> /scripts/docker/merged_list_file.sh
    done
    # 启用京价保
    echo "39 0,23 * * * node /scripts/jd_price.js >> /scripts/logs/jd_price.log 2>&1" >> /scripts/docker/merged_list_file.sh
}

function main(){
    # 首次运行时拷贝docker目录下文件
    [[ ! -d /jd_sku ]] && mkdir /jd_sku && cp -rf /scripts/docker/* /jd_sku
    # DIY脚本
    a_jsnum=$(ls -l /scripts | grep -oE "^-.*js$" | wc -l)
    a_jsname=$(ls -l /scripts | grep -oE "^-.*js$" | grep -oE "[^ ]*js$")
    cd / && apk update && apk upgrade && cd / && apk add --no-cache screen bash make wget vim curl python3-dev py3-pip py3-cryptography htop
    cd / && pip3 install wheel telethon pysocks httpx requests Cython
    monkcoder
    wenmoux
    whyour
    nianyuguai
    #zcy01
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
}

main
