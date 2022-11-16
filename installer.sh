#!/bin/sh

CONFIG_CHECK="$(pwd -P)/.env.casinodog"
if [ ! -f "$CONFIG_CHECK" ]; then
  echo "Please place .env.casinodog in working directory, download from https://gitlab.com/casinoman."
  echo "Mirrors: betgreen.cloud, github.com/casino-man, casino-man.app, bragg.app, casinoman.app"
  exit;
fi

NGINX_CHECK="$(pwd -P)/nginx_boilerplate.conf"
if [ ! -f "$NGINX_CHECK" ]; then
  echo "Please place a nginx configuration with the name "nginx_boilerplate.conf". It will read domain && ssl to use from your .env.casinodog file."
  echo "Mirrors: betgreen.cloud, github.com/casino-man, casino-man.app, bragg.app, casinoman.app"
  exit;
fi

SSL_CERT="$(pwd -P)/cert.crt"
if [ ! -f "$SSL_CERT" ]; then
  echo "Place your SSL certificate in working directory as: cert.crt"
  echo "If you need to generate SSL keys, run the certbot.sh script in this folder."
  exit;
fi

SSLKEY_CHECK="$(pwd -P)/private.key"
if [ ! -f "$SSLKEY_CHECK" ]; then
  echo "Place your SSL private key in working directory as: private.key"
  echo "If you need to generate SSL keys, run the certbot.sh script in this folder."
  exit;
fi

apt-get update -y
apt-get install sudo -y
sudo apt-get update -y
sudo apt-get install curl -y --no-install-recommends
dist=`grep DISTRIB_ID /etc/*-release | awk -F '=' '{print $2}'`
if [ "$dist" == "Ubuntu" ]; then
  sudo apt install ca-certificates apt-transport-https software-properties-common --no-install-recommends -y
  sudo add-apt-repository ppa:ondrej/php -y
else
  echo "debian php repositories added"
  sudo apt install -y lsb-release ca-certificates apt-transport-https software-properties-common gnupg2 --no-install-recommends -y
  echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/sury-php.list
  curl -fsSL  https://packages.sury.org/php/apt.gpg| sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/sury-keyring.gpg
fi
sudo apt update
sudo apt-get install nano -y --no-install-recommends
sudo apt-get install php8.1-fpm --no-install-recommends -y
sudo apt-get install php8.1-sqlite --no-install-recommends -y
sudo apt-get install php-curl --no-install-recommends -y
sudo apt-get install php-zip --no-install-recommends -y
sudo apt-get install php-dom --no-install-recommends -y
sudo apt-get install php-xml --no-install-recommends -y
sudo apt-get install php-redis --no-install-recommends -y
sudo service php8.1-fpm restart
sudo apt-get install nginx -y --no-install-recommends
sudo apt-get install git -y --no-install-recommends
sudo apt-get install wget -y --no-install-recommends
sudo apt-get install openssl -y --no-install-recommends

#printing all variables from .env.casinodog to export
#export $(cat .env.casinodog | sed '/^$/d; /#[[:print:]]*$/d')
export $(grep -v '^#' .env.casinodog | xargs)

#composer install
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php -r "if (hash_file('sha384', 'composer-setup.php') === '55ce33d7678c5a611085589f1f3ddf8b3c52d662cd01d4ba75c0ee0459970c2200a51f492d557530c71c15d8dba01eae') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
php composer-setup.php
php -r "unlink('composer-setup.php');"
sudo mv composer.phar /usr/local/bin/composer
sudo chattr -i /usr/local/bin/composer

#setting up nginx template
sudo cp nginx_boilerplate.conf ${APP_URL#*//}.conf
sed -i "s|APP_HOST_REPLACE|${APP_URL#*//}|g" ${APP_URL#*//}.conf
sed -i "s|APP_PATH_REPLACE|$(pwd -P)/casinodog/public|g" ${APP_URL#*//}.conf
sudo ln -s $(pwd -P)/${APP_URL#*//}.conf /etc/nginx/sites-enabled/${APP_URL#*//}.conf
sudo mkdir /etc/nginx/ssl
sudo mkdir /etc/nginx/ssl/${APP_URL#*//}
echo "Going to generate dhparams, this can take a bit."
sudo openssl dhparam -out /etc/nginx/ssl/dhparams.pem 1024
sudo chattr -i /etc/nginx/ssl/dhparams.pem
sudo cp "$(pwd -P)/cert.crt" "/etc/nginx/ssl/"${APP_URL#*//}"/cert.crt"
sudo cp "$(pwd -P)/private.key" "/etc/nginx/ssl/"${APP_URL#*//}"/private.key"

#importing laravel
sudo git clone https://github.com/laravel/laravel.git casinodog
sudo mkdir wainwright-tmp
sudo git clone "${CASINODOG_REMOTE_GIT}" wainwright-tmp/casino-dog
sudo git clone "${CASINODOG_OPERATOR_API_GIT}" wainwright-tmp/casino-dog-operator-api
sudo rm -r casinodog/.git
sudo rm -r casinodog/.github
sudo mv wainwright-tmp casinodog/.wainwright
sudo cp .env.casinodog casinodog/.env
sudo cp .env.casinodog casinodog/.env.casinodog
cp composer_template.json casinodog/composer.json

#installing redis
sudo mkdir "$(pwd -P)"/redis-setup
REDIS_VER=7.0.5
UPDATE_LINUX_PACKAGES=false
REDIS_INSTANCE_NAME=redis-server
REDIS_INSTANCE_PORT=16379
if [ ! -f member-setup.sh ]
then
        cd redis-setup && wget https://github.com/ziyasal/redisetup/raw/master/member-setup.sh
fi
sudo sh member-setup.sh master $REDIS_VER $UPDATE_LINUX_PACKAGES $REDIS_INSTANCE_NAME $REDIS_INSTANCE_PORT
sed -i "s|"# bind 127.0.0.1"|"bin 127.0.0.1"|g" /etc/redis-server/redis.conf
service redis-server restart


echo "done"
exit;

