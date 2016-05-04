#!/bin/bash

# 共通設定ファイル読み込み
global="$(readlink -f $0 | xargs dirname)/conf/global.conf"
if [ ! -e "${global}" ]; then
    echo "先にsetup.shを実行してください。" >/dev/stderr
    exit
else
    source "${global}"
fi


# root権限の確認
is_root

# logrotate実行
# 実行結果が正常ならそのまま進行、失敗した場合はエラー終了
${logrotate} ${rotate_conf} >>"${log_dir}/logrotate.log" 2>&1
if [ $? -ne 0 ]; then
    echo "logrotate failed at $(date '+%F %T')" >> "${log_dir}/logrotate.log"
    exit 1
fi

# バックアップ開始時間書き出し
put_stdout "Backup started at $(date '+%F %T')" | tee -a ${log_file}

if [ -x "${mysqldump}" ]; then
    put_stdout "mysqldumpを開始します。" | tee -a ${log_file}
    ${base_dir}/mysqldump.sh 2>&1 | tee -a ${log_file}
    put_stdout "mysqldumpを終了しました。" | tee -a ${log_file}
    put_stdout "" | tee -a ${log_file}
fi

oldIFS=${IFS}
IFS=$'\n'
if [ -e "${target_conf}" ]; then
    for target_list in $(cat ${target_conf}); do
        target=$(echo "${target_list}")
        put_stdout "${target} のバックアップを開始します。" | tee -a ${log_file}
        ${base_dir}/file.sh "${target}" 2>&1 | tee -a ${log_file}
        put_stdout "${target} のバックアップを終了しました。" | tee -a ${log_file}
        put_stdout "" | tee -a ${log_file}
    done
fi

# バックアップ終了時間書き出し
put_stdout "Backup ended at $(date '+%F %T')" | tee -a ${log_file}
