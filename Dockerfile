FROM php:7.3.7-fpm-buster

# install nginx

RUN rm /etc/apt/preferences.d/no-debian-php && apt-get update && apt-get install -y \
    nginx \
    wget \
    alien \
    libaio1 \
    php-pear \
    supervisor \
    g++ \
    vim \
    curl \
    libpq-dev \
    libmemcached-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libmcrypt-dev \
    libpng-dev \
    libmcrypt-dev \
    libicu-dev \
    libsqlite3-dev \
    libssl-dev \
    libcurl3-dev \
    libxml2-dev \
    libzzip-dev \
    libzip-dev \
    --no-install-recommends apt-utils \
    && rm -r /var/lib/apt/lists/*

COPY ./oracle_client /oracle-client
RUN alien -i /oracle-client/oracle-instantclient12.1-basic-12.1.0.2.0-1.x86_64.rpm && \
    alien -i /oracle-client/oracle-instantclient12.1-sqlplus-12.1.0.2.0-1.x86_64.rpm && \
    alien -i /oracle-client/oracle-instantclient12.1-devel-12.1.0.2.0-1.x86_64.rpm

RUN rm -r -f /oracle-client/oracle-instantclient12.1-basic-12.1.0.2.0-1.x86_64.rpm && \
    rm -r -f /oracle-client/oracle-instantclient12.1-sqlplus-12.1.0.2.0-1.x86_64.rpm && \
    rm -r -f /oracle-client/oracle-instantclient12.1-devel-12.1.0.2.0-1.x86_64.rpm

ENV LD_LIBRARY_PATH /usr/lib/oracle/12.1/client64/lib/
ENV PKG_CONFIG_PATH /oracle-client/

RUN echo 'instantclient,/usr/lib/oracle/12.1/client64/lib/' | pecl install oci8 mcrypt-1.0.2

RUN docker-php-ext-configure pdo_oci --with-pdo-oci=instantclient,/usr/lib/oracle/12.1/client64/lib/ \
    && docker-php-ext-install \
        gd \
        bcmath \
        pdo_mysql \
        pdo_pgsql \
        zip \
        mysqli \
        pdo_oci \
    && docker-php-ext-enable \
        oci8 \
        mcrypt

COPY default.conf /etc/nginx/sites-enabled/default

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Install adminer and default theme
RUN wget http://www.adminer.org/latest.php -O /var/www/index.php
RUN wget https://raw.github.com/vrana/adminer/master/designs/hever/adminer.css -O /var/www/adminer.css
WORKDIR /var/www

COPY ./entrypoint.sh /scripts/entrypoint.sh
ENTRYPOINT ["sh", "/scripts/entrypoint.sh"]
CMD ["/usr/bin/supervisord"]

EXPOSE 80 443
