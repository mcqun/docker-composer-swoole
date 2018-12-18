FROM mcqun/docker-php7:latest
LABEL maintainer="Mcqun <mchqun@126.com>" version="1.0"

##
# ---------- env settings ----------
##

ENV SWOOLE_VERSION=4.2.9 \
  #  install and remove building packages
  PHPIZE_DEPS="autoconf dpkg-dev dpkg file g++ gcc libc-dev make pkgconf re2c pcre-dev zlib-dev"

##
# install php extensions
##

# 下载太慢，所以可以先下载好
# COPY deps/swoole-${SWOOLE_VERSION}.tar.gz swoole.tar.gz
RUN set -ex \
  && apk update \
  # libs for swoole extension. libaio linux-headers
  && apk add --no-cache libstdc++ openssl nghttp2-dev \
  && apk add --no-cache --virtual .build-deps $PHPIZE_DEPS libaio-dev openssl-dev \
  # --------- php extension: swoole ---------
  && cd /tmp \
  && curl -SL "https://github.com/swoole/swoole-src/archive/v${SWOOLE_VERSION}.tar.gz" -o swoole.tar.gz \
  && mkdir -p swoole \
  && tar -xf swoole.tar.gz -C swoole --strip-components=1 \
  && rm swoole.tar.gz \
  && ( \
  cd swoole \
  && phpize \
  && ./configure --enable-mysqlnd --enable-openssl --enable-http2\
  && make -j$(nproc) && make install \
  ) \
  && rm -r swoole \
  && echo "extension=swoole.so" > /usr/local/etc/php/conf.d/20_swoole.ini \
  # ---------- install composer ---------
  && php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
  && php -r "if (hash_file('sha384', 'composer-setup.php') === '93b54496392c062774670ac18b134c3b3a95e5a5e5c8f1a9f115f203b75bf9a129d5daa8ba6a13e2cc8a1da0806388a8') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" \
  && php composer-setup.php --install-dir=/usr/local/bin --filename=composer \
  && php -r "unlink('composer-setup.php');" \
  && php -v \
  && composer --version \
  # ---------- clear works ----------
  && apk del .build-deps \
  && rm -rf /var/cache/apk/* /tmp/* /usr/share/man \
  && echo -e "\033[42;37m Build Completed :).\033[0m\n"

EXPOSE 9501