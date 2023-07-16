echo “**** Update base AMI ****”
dnf update -y
echo “**** Installing MySQL, Apache and PHP ****”
dnf install wget php-mysqlnd httpd php-fpm php-mysqli mariadb105-server php-json php php-devel -y
systemctl start mariadb
echo “**** Creating Wordpress Database and User ****”
mysql -uroot -proot -e "CREATE DATABASE wordpressdb /*\!40100 DEFAULT CHARACTER SET utf8 */;"
mysql -uroot -proot -e "CREATE USER wordpressuser@localhost IDENTIFIED BY '<wppassword>';"
mysql -uroot -proot -e "GRANT ALL PRIVILEGES ON wordpressdb.* TO wordpressuser@localhost IDENTIFIED BY '<wppassword>';"
mysql -uroot -proot -e "FLUSH PRIVILEGES;"
echo “**** Installing and Configuring Wordpress ****”
cd /var/www/html
curl -O https://wordpress.org/latest.tar.gz
tar -zxvf latest.tar.gz -C /var/www/html
rm latest.tar.gz
cp -a /var/www/html/wordpress/. /var/www/html
rm -rf /var/www/html/wordpress
mkdir wp-content/uploads wp-content/cache
chown apache:apache wp-content/uploads wp-content/cache
cp wp-config-sample.php wp-config.php
sed -ie "s/database_name_here/wordpressdb/" wp-config.php
sed -ie "s/username_here/wordpressuser/" wp-config.php
sed -ie "s/password_here/<wppassword>/" wp-config.php
curl https://api.wordpress.org/secret-key/1.1/salt/ >> wp-config.php
echo "# BEGIN WordPress" >> .htaccess
echo "<IfModule mod_rewrite.c>" >> .htaccess
echo "RewriteEngine On" >> .htaccess
echo "RewriteBase /" >> .htaccess
echo "RewriteRule ^index\.php$ - [L]" >> .htaccess
echo "RewriteCond %{REQUEST_FILENAME} !-f" >> .htaccess
echo "RewriteCond %{REQUEST_FILENAME} !-d" >> .htaccess
echo "RewriteRule . /index.php [L]" >> .htaccess
echo "</IfModule>" >> .htaccess
echo "# END WordPress" >> .htaccess
chmod 666 /var/www/html/.htaccess
sed -i "/^<Directory \"\/var\/www\/html\">/,/^<\/Directory>/{s/AllowOverride None/AllowOverride All/g}" /etc/httpd/conf/httpd.conf
systemctl start httpd
echo “**** MySQL is unsecure. Please change the password ****”
