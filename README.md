# server-backup

rdiff-backupを用いて差分バックアップを行います。


## インストール
```
# mkdir /home/backup/
# git clone https://github.com/hassy-6thsense/server-backup.git /home/backup/server-backup
```


## セットアップ

1. rootユーザーのパスフレーズなし公開鍵を作成 (`# ssh-keygen`)
rootユーザー以外ではパーミッション情報が維持できません。
2. 作成した公開鍵 (id_rsa.pub) をバックアップサーバーのユーザーの鍵リストに登録
3. `# ./setup.sh`
色々聞かれますが、基本的にエンターを押し続けていれば問題ありません。
4. `# ./target.sh -a <バックアップ対象ファイル・ディレクトリ>`
対象ファイル・ディレクトリ1つにつき1回ずつ行ってください。
5. `# ./cron.sh`
対話的にスケジュールを設定する必要があります (デフォルトは毎日)。


# その他使い方

- バックアップ対象から除外する場合
`# ./target.sh -d  <バックアップ対象ファイル・ディレクトリ>`
- cronのスケジュールを変更する場合
`# ./cron.sh -m`
- cronの定期実行を解除する場合
`# ./cron.sh -d`


## バージョン情報

### 4.0.0 (4 May 2016)
- GitHubへの移行に伴い、機密情報を削除しコミット情報初期化
- 機密情報削除のため諸々更新

### 3.1.0 (22 Sep 2014)
- MySQLのダンプファイルをデータベースごとに分割する仕様に変更
- Debianでcronが動かないバグを修正

### 3.0.1 (31 Jul 2014)
- SSHポート番号を指定できるよう修正
- バグ修正

### 3.0.0 (30 Jul 2014)
- 名称変更
- バックアップにrdiff-backupを用いる方式に変更
- バックアップ対象から除外する機能を追加
- cronへの登録関連機能を追加

### 2.2.0 (17 Jul 2014)
- tarball.shをバックアップ元から転送して実行するように変更

### 2.1.1 (14 Jul 2014)
- rsyncに --rshオプションを追加
- setup.sh実行時にtarget.confをリセットするよう修正

### 2.1.0 (14 Jul 2014)
- バックアップ先でディレクトリが重複していた問題を修正
- rsyncの一部オプションの削除
- README.mdを作成

### 2.0.1 (02 Jun 2014)
- mysqldumpのオプションを適切に修正
- mysqldumpのログを出力
- logrotateの間隔を日毎に変更

### 2.0.0 (14 May 2014)
- 大規模改修
- gitbucketへの登録

### 1.0.0 (29 Sep 2012)
- リリース