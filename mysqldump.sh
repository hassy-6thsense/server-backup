#!/bin/bash

# 共通設定ファイル読み込み
global="$(readlink -f $0 | xargs dirname)/conf/global.conf"
if [ ! -e "${global}" ]; then
    echo "先にsetup.shを実行してください。" >/dev/stderr
    exit
else
    source "${global}"
fi

is_root

databases="$(${mysql} --user="${mysql_user}" --password="${mysql_password}" --skip-column-names --silent --execute="SHOW DATABASES")"
for database in ${databases}
do
    if [ "${database}" != "information_schema" ] && [ "${database}" != "performance_schema" ]; then
        echo "dumping: ${database}" >> "${mysql_log_file}"
        # mysqldump実行
        dump_file="${mysql_dir}/$(hostname)_${database}.sql"
        ${mysqldump} --verbose --user="${mysql_user}" --password="${mysql_password}" --debug-check --debug-info --log-error="${mysql_log_file}" --quote-names --skip-lock-tables --single-transaction --flush-logs --master-data=2 "${database}" > "${dump_file}" || put_stderr "${mysqldump}: Error"
    fi
done

# オプション
options="--print"

# SSHポート番号変更
schema="${ssh} -C -p ${remote_port} %s rdiff-backup --server"

# rdiff-backup
${rdiff_backup} ${options} --remote-schema="${schema}" "${mysql_dir}" "${remote_user}@${remote_addr}::/${dest_mysql}/"
