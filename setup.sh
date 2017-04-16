#!/bin/bash

function set_remote()
{
    local input=""

    read -ep "SSH接続ユーザーを入力 [${remote_user}]: " input
    if [ "${input}" != "" ]; then
        remote_user="${input}"
    fi

    read -ep "バックアップ先を入力 [${remote_addr}]: " input
    if [ "${input}" != "" ]; then
        remote_addr="${input}"
    fi

    read -ep "バックアップ先のSSHポート番号 [${remote_port}]: " input
    if [ "${input}" != "" ] && [ ${input} -gt 0 ]; then
        remote_port="${input}"
    fi

    return 0
}


function set_ssh()
{
    local input=""

    read -ep "sshコマンド [${ssh}]: " input
    if [ "${input}" != "" ]; then
        ssh="${input}"
    fi

    if [ ! -x "${ssh}" ]; then
        read -ep "sshコマンドを指定: " ssh
        set_ssh
    else
        remote_user_home="$(${ssh} ${remote_user}@${remote_addr} -p ${remote_port} 'readlink -e $HOME')"
        dest_base="${remote_user_home}/$(hostname)"
        read -ep "バックアップ保存ベースディレクトリ [${dest_base}]: " input
        if [ "${input}" != "" ]; then
            dest_base="${input}"
        fi

        dest_files="${dest_base}/rootdir/"
        dest_mysql="${dest_base}/mysqldump/"

        ${ssh} ${remote_user}@${remote_addr} -p ${remote_port} "mkdir -p ${dest_files}" || exit_with_message "Error: mkdir ${dest_files} failed"
        ${ssh} ${remote_user}@${remote_addr} -p ${remote_port} "mkdir -p ${dest_mysql}" || exit_with_message "Error: mkdir ${dest_mysql} failed"
    fi

    return 0
}

function set_rdiff_backup()
{
    local input=""

    read -ep "rdiff-backupコマンド [${rdiff_backup}]: " input
    if [ "${input}" != "" ]; then
        rdiff_backup="${input}"
    fi

    if [ ! -x "${rdiff_backup}" ]; then
        read -ep "rdiff-backupコマンドを指定: " rdiff_backup
        set_rdiff_backup
    fi

    return 0
}

function set_logrotate()
{
    local input=""

    read -ep "logrotateコマンド [${logrotate}]: " input
    if [ "${input}" != "" ]; then
        logrotate="${input}"
    fi

    if [ ! -x "${logrotate}" ]; then
        read -ep "logrotateコマンドを指定: " logrotate
        set_logrotate
    fi

    return 0
}

function set_mysqldump()
{
    local input=""
    local user=""
    local pass=""
    local dir=""

    if [ -x "${mysql}" ] && [ -x "${mysqldump}" ]; then
        read -ep "MySQLのバックアップを行いますか？ [Y/n]: " input
        if [ $(expr "${input}" : [^yY]) -ne 0 ]; then
            mysql=""
            mysqldump=""
            put_stdout "MySQLのバックアップをスキップします。"
            return 0
        fi

        read -ep "mysqlは [${mysql}] を、mysqldumpは [${mysqldump}] を使用します。よろしいですか？ [Y/n]: " input
        if [ $(expr "${input}" : [^yY]) -ne 0 ]; then
            read -ep "mysqlのパスを入力: " mysql
            read -ep "mysqldumpのパスを入力: " mysqldump
            set_mysqldump
        fi

        false
        while [ $? -ne 0 ]
        do
            read -ep "mysqldump時のユーザー名 [${mysql_user}]: " user
            if [ ! "${user}" ]; then
                user=${mysql_user}
            fi
            read -sep "パスワード [${mysql_password}]: " pass
            if [ ! "${pass}" ]; then
                pass=${mysql_password}
            fi
            put_stdout ""

            ${mysql} --user="${user}" --password="${pass}" --execute="SHOW DATABASES" >/dev/null
        done

        mysql_user=${user}
        mysql_password=${pass}

        read -ep "ダンプファイルの出力先ディレクトリ [${mysql_dir}]: " dir
        if [ "${dir}" ]; then
            mysql_dir=${dir}
        fi
        test -d "${mysql_dir}" || mkdir -p "${mysql_dir}"
    else
        put_stdout "mysqlはインストールされていません。スキップします。"
    fi

    return 0
}

function make_logrotate_conf()
{
    cat <<EOF > "${rotate_conf}"
${log_file} {
    missingok
    notifempty
    daily
    rotate 30
    compress
    create
    start 0
}
EOF

    if [ -x "${mysqldump}" ]; then
        cat <<EOF >> "${rotate_conf}"
${mysql_log_file} {
    missingok
    notifempty
    daily
    rotate 30
    compress
    create
    start 0
}
EOF
    fi
}


# バックアップスクリプト配置ディレクトリ
base_dir="$(readlink -f $0 | xargs dirname)"

conf_dir="${base_dir}/conf"
test -d "${conf_dir}" || mkdir -m 755 -p "${conf_dir}"

log_dir="${base_dir}/log"
test -d "${log_dir}" || mkdir -m 755 -p "${log_dir}"

# 共通関数読み込み
source ${base_dir}/functions.sh || exit 1;

# 各プログラムのパス設定
ssh="$(which ssh)"
rdiff_backup="$(which rdiff-backup)"
logrotate="$(which logrotate)"
mysql="$(which mysql)"
mysqldump="$(which mysqldump)"

# SSH接続ユーザー名
remote_user="server-backup"

# バックアップ対象ホスト・SSHポート番号
remote_addr="localhost"
remote_port="22"

# mysqldump実行時のユーザー名・パスワード
mysql_user="mysqldump"
mysql_password="mysqldump"

# MySQLダンプファイル出力先パス (デフォルト)
mysql_dir="/home/backup/mysqldump/"

# バックアップログファイル名
log_file="${log_dir}/backup.log"

# mysqldumpログファイル名
mysql_log_file="${log_dir}/mysqldump.log"

# logrotateの設定ファイル
rotate_conf="${conf_dir}/logrotate.conf"

# バックアップ対象記述ファイル
target_conf="${conf_dir}/target.conf"

is_root
put_stdout "セットアップを開始します。"
set_remote
set_ssh || exit_with_message "セットアップを中止します。"
set_rdiff_backup || exit_with_message "セットアップを中止します。"
set_logrotate || exit_with_message "セットアップを中止します。"
set_mysqldump
make_logrotate_conf

cat <<EOF > "${target_conf}"
EOF


# 共通設定ファイル書き出し
global="${conf_dir}/global.conf"
cat <<EOF > "${global}"
#!/bin/bash
export base_dir="${base_dir}"
export conf_dir="${conf_dir}"
export log_dir="${log_dir}"

export ssh="${ssh}"
export rdiff_backup="${rdiff_backup}"
export logrotate="${logrotate}"

export mysql="${mysql}"
export mysqldump="${mysqldump}"
export mysql_user="${mysql_user}"
export mysql_password="${mysql_password}"
export mysql_dir="${mysql_dir}"

export remote_user="${remote_user}"
export remote_addr="${remote_addr}"
export remote_port="${remote_port}"
export dest_base="${dest_base}"
export dest_files="${dest_files}"
export dest_mysql="${dest_mysql}"
export log_file="${log_file}"
export mysql_log_file="${mysql_log_file}"
export rotate_conf="${rotate_conf}"
export target_conf="${target_conf}"

source "${base_dir}/functions.sh" || exit 1;

EOF

put_stdout "セットアップが完了しました。"

