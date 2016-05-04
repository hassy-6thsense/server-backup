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

# 引数
target=$1

# バックアップ対象
src="$(readlink -f ${target})"
test -e ${src} || exit_with_message "${src}: No such file or directory"
src="$(readlink -f ${src})"
test -d ${src} && src="${src}/"

# オプション
options="--print --force"

# SSHポート番号変更
schema="${ssh} -C -p ${remote_port} %s rdiff-backup --server"

# バックアップ除外対象指定
# --exclude "path/to/exclude1" --exclude "path/to/exclude2" のように指定する
excludes=""

# rdiff-backup
${rdiff_backup} ${options} --remote-schema="${schema}" --exclude "**${mysql_dir%/}" ${excludes} "${src}" "${remote_user}@${remote_addr}::/${dest_files}/${src}"
