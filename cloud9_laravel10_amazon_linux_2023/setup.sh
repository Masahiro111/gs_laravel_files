# !/bin/sh

echo "MariaDBデフォルト確認"
sudo yum list installed | grep mariadb

echo "Apache, MariaDBの起動"
sudo systemctl start mariadb
sudo mysql
ALTER USER 'root'@'localhost' IDENTIFIED BY 'root';
exit;

echo "MaridaDBの自動起動を有効化"
sudo systemctl enable mariadb
sudo systemctl is-enabled mariadb

echo "Composerインストール"
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/bin/composer
composer

echo "Laravelインストール"
composer create-project "laravel/laravel=10.*" cms 

echo "ディレクトリ移動"
cd cms
composer update

echo  "phpMyAdminを作成する為にディレクトリ移動"
cd public

echo  "phpMyAdminをダウンロード"
wget https://files.phpmyadmin.net/phpMyAdmin/5.1.2/phpMyAdmin-5.1.2-all-languages.zip

echo  "phpMyAdminを解凍"
unzip phpMyAdmin-5.1.2-all-languages.zip

echo  "zipファイルの削除"
rm phpMyAdmin-5.1.2-all-languages.zip

echo  "phpMyAdminのファイル名変更"
mv phpMyAdmin-5.1.2-all-languages phpMyAdmin

echo  "cms 階層に戻る"
cd ..

echo "env ファイルの編集"
sed -i "s/DB_HOST=127\.0\.0\.1.*/DB_HOST=localhost/" ".env"
sed -i "s/DB_DATABASE=laravel.*/DB_DATABASE=c9/" ".env"
sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=root/" ".env"

echo "HTTPS 化の記述"
sed -i '5i\use Illuminate\\Support\\Facades\\URL;' "app/Providers/AppServiceProvider.php"
sed -i "23i\URL::forceScheme('https');" "app/Providers/AppServiceProvider.php"

echo "Laravel Breeze のインストール"
composer require laravel/breeze --dev

php artisan breeze:install -- blade

echo "マイグレーション処理"
php artisan migrate

echo "ログイン画面へのリンクを追加する"
sed -i '$a\'"\n@if (Route::has(\'login\'))\n    <div class=\"hidden fixed top-0 right-0 px-6 py-4 sm:block\">\n        @auth\n            <a href=\"{{ url(\'/dashboard\') }}\" class=\"text-sm text-gray-700 dark:text-gray-500 underline\">Dashboard</a>\n        @else\n        <a href=\"{{ route(\'login\') }}\" class=\"text-sm text-gray-700 dark:text-gray-500 underline\">Log in</a>\n        @if (Route::has(\'register\'))\n        <a href=\"{{ route(\'register\') }}\" class=\"ml-4 text-sm text-gray-700 dark:text-gray-500 underline\">Register</a>\n        @endif\n        @endauth\n    </div>\n@endif" "resources/views/auth/register.blade.php"
sed -i '$a\'"\n@if (Route::has(\'login\'))\n    <div class=\"hidden fixed top-0 right-0 px-6 py-4 sm:block\">\n        @auth\n            <a href=\"{{ url(\'/dashboard\') }}\" class=\"text-sm text-gray-700 dark:text-gray-500 underline\">Dashboard</a>\n        @else\n        <a href=\"{{ route(\'login\') }}\" class=\"text-sm text-gray-700 dark:text-gray-500 underline\">Log in</a>\n        @if (Route::has(\'register\'))\n        <a href=\"{{ route(\'register\') }}\" class=\"ml-4 text-sm text-gray-700 dark:text-gray-500 underline\">Register</a>\n        @endif\n        @endauth\n    </div>\n@endif" "resources/views/auth/login.blade.php"

npm run build

echo "\.gitignore の編集"
sed -i "s/\/public\/build/\/public\/phpMyAdmin/" ".gitignore"

echo "MariaDB の設定 -----------------------"
echo "ユーザー名： root"
echo "パスワード： root"
echo ""
echo "「あなたのドメイン/phpMyAdmin/index.php」にブラウザからアクセスしてphpMyAdmin を操作できます"
echo "「cd cms」コマンドを実行してから「php artisan serve --port=8080」を実行すると簡易サーバーが立ち上がります"
echo "--------------------------------------"
