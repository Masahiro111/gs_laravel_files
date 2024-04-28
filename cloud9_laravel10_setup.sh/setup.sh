# !/bin/sh
echo "Laravel と Laravel Breeze のインストール"
echo ""
echo "[hint] インストール前に git の設定を行います"
echo "[hint] 登録した「名前」及び「メールアドレス」はコミット履歴に登録されます"
echo "[hint] （GitHub にプッシュした際、登録した「名前」や「メールアドレス」を閲覧できるので注意して登録してください）"
echo ""
echo "gitに登録するお名前を入力（例：usagi）"
read username
echo "gitに登録するメールアドレスを入力（例：usagi@example.com）"
read useremail
git config --global init.defaultBranch main
git config --global user.name "$username"
git config --global user.email "$useremail"

echo "\n 1.パッケージのアップデートしました\n"
sudo yum update -y

echo "\n 3.amazon-linux-extrasをアップデートしました\n "
sudo yum update -y amazon-linux-extras

echo  "\n 4.amazon-linux-extrasで使用中のパッケージと使えるパッケージを確認\n "
amazon-linux-extras

echo  "\n 5.lamp-mariadb10.2-php7.2を使用停止しました\n "
sudo amazon-linux-extras disable lamp-mariadb10.2-php7.2

echo  "\n 7-1.インストールするパッケージの案内があったので、表示されたコマンドを実行しました\n "
yes | sudo yum clean metadata
yes | sudo yum install php-cli php-pdo php-fpm php-mysqlnd

echo  "\n 7-2.インストールするパッケージの案内があったので、表示されたコマンドを実行しました\n "
yes | sudo yum install php-cli php-common php-devel php-fpm php-gd php-mysqlnd php-mbstring php-pdo php-xml

echo  "\n 8-1.apacheの再起動しました\n "
yes | sudo systemctl restart httpd.service

echo  "\n 8-2.php-fpmの再起動しました\n "
yes | sudo systemctl restart php-fpm.service

echo  "\n 9.xdebugの設定を再度インストールしました\n "
yes | sudo yum install php-pear php-devel
yes | sudo pecl uninstall xdebug
yes | sudo pecl install xdebug

echo  "\n 10.expectコマンドをインストール\n "
yes | sudo yum install expect

echo  "\n 11.MariaDBデフォルト確認しました\n "
sudo yum list installed | grep mariadb

echo  "\n 12.MariaDBのインストールしました\n "
sudo amazon-linux-extras install mariadb10.5 -y

echo  "\n 13.Apache, MariaDBの起動しました\n "
sudo systemctl start mariadb

echo  "\n 14-1.MariaDBの初期設定を自動で行なっています\n "
# !/bin/sh
expect -c '
    set timeout 10;
    spawn sudo mysql_secure_installation
    expect "Enter current password for root (enter for none):";
    send "\n";
    expect "Switch to unix_socket authentication";
    send "y\n";
    expect "Set root password?";
    send "y\n";
    expect "New password:";
    send "root\n";
    expect "Re-enter new password:";
    send "root\n";
    expect "Remove anonymous users?";
    send "y\n";
    expect "Disallow root login remotely?";
    send "y\n";
    expect "Remove test database and access to it?";
    send "y\n";
    expect "Reload privilege tables now?";
    send "y\n";
    interact;'


echo  "\n 14-2.MaridaDBの自動起動を有効化しました\n "
sudo systemctl enable mariadb
sudo systemctl is-enabled mariadb

echo  "\n 15-1. Composerインストール（バージョン指定）しました\n "
curl -sS https://getcomposer.org/installer | php -- --version=2.6.5

echo  "\n 15-2. Composerのパスを通しました\n "
sudo mv composer.phar /usr/bin/composer

echo  "\n 15-3. Composerインストールできたかチェックしました\n "
composer

echo  "\n 16-1. Laravelプロジェクトをバージョン10指定で作成します\n "
composer create-project "laravel/laravel=10.*" cms

echo  "\n 17-1. phpMyAdminを作成する為にディレクトリ移動\n "
cd cms

echo  "\n 17-2. phpMyAdminを作成する為にディレクトリ移動\n "
cd public

echo  "\n 17-3. phpMyAdminをダウンロード\n "
wget https://files.phpmyadmin.net/phpMyAdmin/5.1.2/phpMyAdmin-5.1.2-all-languages.zip

echo  "\n 17-4. phpMyAdminを解凍\n "
unzip phpMyAdmin-5.1.2-all-languages.zip

echo  "\n zipファイルの削除\n "
rm phpMyAdmin-5.1.2-all-languages.zip

echo  "\n 17-5. phpMyAdminのファイル名変更\n "
mv phpMyAdmin-5.1.2-all-languages phpMyAdmin

echo  "\n 17-6. cms階層に戻る\n "
cd ..

echo  "\n 17-7. 親階層に戻る\n "
cd ..

echo "MySQLにログインしてデータベースの作成"
mysql -u root -proot << EOF
create database c9;
show databases;
exit
EOF

echo "env ファイルの編集"
cd cms
sed -i "s/DB_HOST=127\.0\.0\.1.*/DB_HOST=localhost/" ".env"
sed -i "s/DB_DATABASE=laravel.*/DB_DATABASE=c9/" ".env"
sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=root/" ".env"

echo "HTTPS 化の記述"
sed -i '5i\use Illuminate\\Support\\Facades\\URL;' "app/Providers/AppServiceProvider.php"
sed -i "23i\URL::forceScheme('https');" "app/Providers/AppServiceProvider.php"

echo "Laravel Breeze のインストール"
composer require laravel/breeze --dev

php artisan breeze:install --dark -- blade

echo "マイグレーション処理"
php artisan migrate

echo "ログイン画面へのリンクを追加する"
sed -i '$a\'"\n@if (Route::has(\'login\'))\n    <div class=\"hidden fixed top-0 right-0 px-6 py-4 sm:block\">\n        @auth\n            <a href=\"{{ url(\'/dashboard\') }}\" class=\"text-sm text-gray-700 dark:text-gray-500 underline\">Dashboard</a>\n        @else\n        <a href=\"{{ route(\'login\') }}\" class=\"text-sm text-gray-700 dark:text-gray-500 underline\">Log in</a>\n        @if (Route::has(\'register\'))\n        <a href=\"{{ route(\'register\') }}\" class=\"ml-4 text-sm text-gray-700 dark:text-gray-500 underline\">Register</a>\n        @endif\n        @endauth\n    </div>\n@endif" "resources/views/auth/register.blade.php"
sed -i '$a\'"\n@if (Route::has(\'login\'))\n    <div class=\"hidden fixed top-0 right-0 px-6 py-4 sm:block\">\n        @auth\n            <a href=\"{{ url(\'/dashboard\') }}\" class=\"text-sm text-gray-700 dark:text-gray-500 underline\">Dashboard</a>\n        @else\n        <a href=\"{{ route(\'login\') }}\" class=\"text-sm text-gray-700 dark:text-gray-500 underline\">Log in</a>\n        @if (Route::has(\'register\'))\n        <a href=\"{{ route(\'register\') }}\" class=\"ml-4 text-sm text-gray-700 dark:text-gray-500 underline\">Register</a>\n        @endif\n        @endauth\n    </div>\n@endif" "resources/views/auth/login.blade.php"

npm run build

echo "\.gitignore の編集"
sed -i "s/\/public\/build/\/public\/phpMyAdmin/" ".gitignore"

echo "ローカルリポジトリの作成"
git init
git add .
git commit -m "first commit"

echo "key の生成"

expect -c '
    spawn ssh-keygen -t rsa
    expect -re "Enter .*"
    send "\n"
    expect -re "Enter .*"
    send "\n"
    expect -re "Enter .*"
    send "\n"
    interact;'
    
echo ""
echo ""
echo ""
echo "[hint] GitHub に登録する公開鍵を表示します。"
echo "[hint] https://github.com/settings/ssh/new にアクセスして"
echo "[hint] 以下に表示される公開鍵情報を登録してください。"
echo ""
echo "ここから公開鍵をコピー -----------------------"
cat ~/.ssh/id_rsa.pub
echo "ここまで公開鍵をコピー -----------------------"
echo ""
echo "MariaDB の設定 -----------------------"
echo "ユーザー名： root"
echo "パスワード： root"
echo ""
echo "「あなたのドメイン/phpMyAdmin/index.php」にブラウザからアクセスしてphpMyAdmin を操作できます"
echo "「cd cms」コマンドを実行してから「php artisan serve --port=8080」を実行すると簡易サーバーが立ち上がります"
echo "--------------------------------------"
