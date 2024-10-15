ARG OSTICKET_VERSION=1.18.1
ARG PHP_VERSION=8.2

ENV HTTP_PORT 8070
ENV UID=$HOST_UID
ENV GID=$HOST_GID
ENV USERNAME='osticket'
ENV ENABLE_=value
FROM php:${PHP_VERSION}-apache
RUN \
	apt update &&
	apt install --no-install-recommends wget unzip msmtp php$PHP_VERSION php$PHP_VERSION-ldap php$PHP_VERSION-gd php$PHP_VERSION-imap php$PHP_VERSION-xml php$PHP_VERSION-json php$PHP_VERSION-mbstring php$PHP_VERSION-phar php$PHP_VERSION-intl php$PHP_VERSION-fileinfo php-apcu php$PHP_VERSION-opcache  &&
	mkdir /app &&
	wget -O '/tmp/osticket.tar.gz' "https://github.com/osTicket/osTicket/releases/download/v${OSTICKET_VERSION}/osTicket-v${OSTICKET_VERSION}.zip" &&
	tar xzf  '/tmp/osticket.tar.gz' -C /app &&
	groupadd -g "$GID" "$USERNAME" && 
	useradd -u "$UID" "$USERNAME" && 
COPY msmtp.conf /etc/msmtp
USER $USERNAME
c