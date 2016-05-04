#!/bin/bash

# 共通設定ファイル読み込み
global="$(readlink -f $0 | xargs dirname)/conf/global.conf"
if [ ! -e "${global}" ]; then
    echo "先にsetup.shを実行してください。" >/dev/stderr
    exit
else
    source "${global}"
fi


function add_target() {
    target="$(readlink -f $1)"
    if [ ! -e "${target}" ]; then
        exit_with_message "バックアップ対象のファイル/ディレクトリが存在しません。"
    fi

    if [ "${target}" = "$(readlink -f ${mysql_dir})" ]; then
        exit_with_message "ダンプファイル保存ディレクトリは除外されます。"
    fi

    if [ -d "${target}" ]; then
        ${ssh} ${remote_user}@${remote_addr} -p ${remote_port} "mkdir -p ${dest_files}/${target}/"
    else
        ${ssh} ${remote_user}@${remote_addr} -p ${remote_port} "mkdir -p ${dest_files}/$(dirname ${target})"
    fi

    IFS=$'\n'
    target_list=()
    if [ -e "${target_conf}" ]; then
        for line in $(cat "${target_conf}")
        do
            line=$(readlink -f ${line})
            if [ "${line}" = "${target}" ]; then
                continue
            else
                target_list=("${target_list[*]}" "${line}")
            fi
        done
    fi

    target_list=("${target_list[*]}" "${target}")
    target_list=($(echo "${target_list[*]}" | sort))

    echo "${target_list[*]}" > ${target_conf}

    put_stdout "[${target}] をバックアップ対象に追加しました。"
}

function delete_target() {
    if [ ! -e "${target_conf}" ]; then
        exit_with_message "バックアップ対象設定ファイルが存在しません。"
    fi

    target="$(readlink -f $1)"

    IFS=$'\n'
    target_list=()
    for line in $(cat "${target_conf}")
    do
        line=$(readlink -f ${line})
        if [ "${line}" = "${target}" ]; then
            continue
        else
            target_list=("${target_list[*]}" "${line}")
        fi
    done

    target_list=($(echo "${target_list[*]}" | sort))
    echo "${target_list[*]}" > ${target_conf}

    put_stdout "[${target}] をバックアップ対象から除外しました。"
}

function usage_exit() {
    exit_with_message "Usage: $0 [-a target] | $0 [-d target]"
}

is_root

while getopts a:d:h OPT
do
    case ${OPT} in
        a)
            add_target "${OPTARG}"
            break
            ;;
        d)
            delete_target "${OPTARG}"
            break
            ;;
        h)
            usage_exit
            ;;
        \?)
            usage_exit
            ;;
    esac
done

shift $((OPTIND - 1))

if [ "${OPTIND}" = 1 ]; then
    usage_exit
fi
