FROM ubuntu:18.04

RUN apt update

# Install tzdata to avoid getting a prompt when trying to install packages later.
RUN export DEBIAN_FRONTEND=noninteractive
RUN apt install -y tzdata
RUN export DEBIAN_FRONTEND=

# Install binaries.
RUN apt install -y sudo
RUN apt install -y vim
RUN apt install -y nodejs npm composer
RUN apt install -y git unzip
RUN apt install -y php php-mbstring php-dom
RUN apt install -y curl
RUN apt install -y nginx
RUN apt install -y php-fpm php-mysql php-gd
RUN npm install -g n
RUN n stable
RUN apt install -y libpng-dev

# Configure one PHP variable, as recommended by Digital Ocean
# https://www.digitalocean.com/community/tutorials/how-to-install-linux-nginx-mysql-php-lemp-stack-in-ubuntu-16-04
RUN sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/' /etc/php/7.2/fpm/php.ini

# Create "deploy" user, make them a sudoer, make sudoers password-less.
RUN useradd --user-group --create-home --shell /bin/bash deploy
RUN adduser deploy sudo
RUN sed -i 's/%sudo\tALL=(ALL:ALL) ALL/%sudo\tALL=(ALL:ALL) NOPASSWD:ALL/' /etc/sudoers

# Add Laravel with Elixir.
USER deploy
RUN mkdir ~/libs
WORKDIR /home/deploy/libs
RUN composer create-project --prefer-dist laravel/laravel laravel "5.6.*"
RUN chmod -R 777 laravel/storage laravel/bootstrap/cache/
WORKDIR /home/deploy/libs/laravel
RUN npm install
RUN sed -i s'/DB_HOST=127.0.0.1/DB_HOST=mysql/' .env
RUN sed -i s'/DB_DATABASE=homestead/DB_DATABASE=db/' .env
RUN sed -i s'/DB_USERNAME=homestead/DB_USERNAME=db/' .env
RUN sed -i s'/DB_PASSWORD=secret/DB_PASSWORD=db/' .env

# Add some files
USER root
COPY rootfs/ /
RUN chown -R deploy:deploy /home/deploy

# Create a web root
USER deploy
RUN mkdir -p ~/public/app
WORKDIR /home/deploy/public/app
RUN mkdir ~/public/app/node_modules
RUN mkdir -p ~/public/app/vendor/bin

ENTRYPOINT /entrypoint.sh
