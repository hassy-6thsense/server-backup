#!/bin/bash

# 共通設定ファイル読み込み
global="$(readlink -f $0 | xargs dirname)/conf/global.conf"
if [ ! -e "${global}" ]; then
    echo "先にsetup.shを実行してください。" >/dev/stderr
    exit
else
    source "${global}"
fi

cron_script="server-backup"

function regist_cron() {
    local schedule=""

    put_stdout "1: 毎時"
    put_stdout "2: 毎日 (デフォルト)"
    put_stdout "3: 毎週"
    put_stdout "4: 毎月"
    read -ep "バックアップスケジュールを選択してください。 [1/2/3/4]: " schedule
    case ${schedule} in
        1)
            cron_dir="/etc/cron.hourly"
            ln -ivs "${base_dir}/${cron_script}.sh" "${cron_dir}/${cron_script}"
            ;;
        3)
            cron_dir="/etc/cron.weekly"
            ln -ivs "${base_dir}/${cron_script}.sh" "${cron_dir}/${cron_script}"
            ;;
        4)
            cron_dir="/etc/cron.monthly"
            ln -ivs "${base_dir}/${cron_script}.sh" "${cron_dir}/${cron_script}"
            ;;
        *)
            cron_dir="/etc/cron.daily"
            ln -ivs "${base_dir}/${cron_script}.sh" "${cron_dir}/${cron_script}"
            ;;
    esac

    return 0
}

function unregist_cron() {
    local cron_dir=""
    local cron_dirList="/etc/cron.hourly /etc/cron.daily /etc/cron.weekly /etc/cron.monthly"

    for cron_dir in ${cron_dirList}
    do
        local path="${cron_dir}/${cron_script}"
        if [ -e "${path}" ]; then
            rm -v ${path}
        fi
    done
}

function usage_exit() {
    put_stdout "regist cron: $0"
    put_stdout "unregist cron: $0 -d"
    exit 0
}


is_root

while getopts dhm OPT
do
    case ${OPT} in
        d)
            unregist_cron
            break
            ;;
        h)
            usage_exit
            ;;
        m)
            unregist_cron
            regist_cron
            break
            ;;
        *)
            usage_exit
            ;;
    esac
done

shift $((OPTIND - 1))

if [ "${OPTIND}" = 1 ]; then
    regist_cron
fi

