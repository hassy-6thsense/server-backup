#!/bin/bash

function put_stdout()
{
	echo "$1" >/dev/stdout
}

function put_stderr()
{
	echo "$1" >/dev/stderr
}

function exit_with_message()
{
	put_stderr "$1"
	exit;
}

function is_root() {
	if [ "$(id -u)" != "0" ]; then
		put_stderr "root権限で実行してください。"
		exit 1
	fi
}

