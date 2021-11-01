FROM php:7.4

ARG TIMEZONE=UTC

# Set timezone
RUN ln -snf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime && echo ${TIMEZONE} > /etc/timezone \
  && printf '[PHP]\ndate.timezone = "%s"\n', ${TIMEZONE} > /usr/local/etc/php/conf.d/tzone.ini \
	&& "date"

# install platform reqs
RUN set -ex; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		git \
		tini \
		wget \
		zip

# install the PHP extensions we need
RUN set -ex; \
	\
	savedAptMark="$(apt-mark showmanual)"; \
	\
	apt-get update; \
	apt-get install -y --no-install-recommends \
		$PHPIZE_DEPS \
	; \
	apt-get install -y --no-install-recommends \
		freetds-dev \
		libgmp-dev \
		libzip-dev \
		libwebp-dev \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libmcrypt-dev \
    libpng-dev \
    libbz2-dev \
    libcurl4-gnutls-dev \
    libxml2-dev \
    libssl-dev \
    libc-client-dev \
    libkrb5-dev \
    zlib1g-dev \
    libicu-dev \
    libsqlite3-dev \
    libpspell-dev \
    libreadline-dev \
    libedit-dev \
    librecode-dev \
    libsnmp-dev \
    libtidy-dev \
    libxslt1-dev \
    libgmp-dev \
    libldb-dev \
    libldap2-dev \
    libsodium-dev \
    librabbitmq-dev \
	; \
	\
	docker-php-ext-configure gd --enable-gd --with-freetype --with-jpeg --with-webp; \
	docker-php-ext-configure imap --with-kerberos --with-imap-ssl; \
	docker-php-ext-install -j$(nproc) \
		bcmath \
		bz2 \
		calendar \
		exif \
		gd \
		gettext \
		gmp \
		iconv \
		imap \
		intl \
		ldap \
		pcntl \
		pdo \
		pdo_mysql \
		snmp \
		soap \
		sockets \
		tidy \
		xsl \
		zip \
	; \
	\
# reset apt-mark's "manual" list so that "purge --auto-remove" will remove all build dependencies
	apt-mark auto '.*' > /dev/null; \
	apt-mark manual $savedAptMark; \
	ldd "$(php -r 'echo ini_get("extension_dir");')"/*.so \
		| awk '/=>/ { print $3 }' \
		| sort -u \
		| xargs -r dpkg-query -S \
		| cut -d: -f1 \
		| sort -u \
		| xargs -rt apt-mark manual; \
	\
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
	rm -rf /var/lib/apt/lists/*

RUN { \
		echo 'memory_limit = 4096M'; \
		echo 'max_input_vars = 1000'; \
	} > /usr/local/etc/php/conf.d/application-recommended.ini

RUN ln -s /usr/bin/tini /sbin/tini

COPY --from=composer /usr/bin/composer /usr/bin/composer
COPY --from=composer /docker-entrypoint.sh /docker-entrypoint.sh

WORKDIR /app

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["composer"]

