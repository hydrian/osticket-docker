# syntax=docker/dockerfile:1
ARG PHP_BASE_VERSION='8.2'
ARG HTTP_PORT_DEFAULT='8070'
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV HTTP_PORT=8070 
ENV	USERNAME='osticket'
ENV PHP_BASE_VERSION='8.1'
ENV TZ='UTC'
ENV OSTICKET_VERSION='1.18.1'

ENV PUID=1000
ENV PGID=1000
RUN \
	ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
	echo $TZ > /etc/timezone && \
	apt-get update && \
	apt-get install -y --no-install-recommends \
		ca-certificates \
		wget \
		unzip \
		msmtp \
		"php${PHP_BASE_VERSION}" \
		"php${PHP_BASE_VERSION}-ldap" \
		"php${PHP_BASE_VERSION}-gd" \
		"php${PHP_BASE_VERSION}-imap" \
		"php${PHP_BASE_VERSION}-xml" \
		"php${PHP_BASE_VERSION}-mbstring" \
		"php${PHP_BASE_VERSION}-phar" \
		"php${PHP_BASE_VERSION}-intl" \
		"php${PHP_BASE_VERSION}-fileinfo" \
		"php${PHP_BASE_VERSION}-apcu" \
		"php${PHP_BASE_VERSION}-gettext" \
		"php-dompdf" \
		"php-phpseclib" \
		"php-auth-sasl" \
		"php-mail" \
		"php-net-smtp" \
		"php-net-socket" \
		"libapache2-mod-php${PHP_BASE_VERSION}"  && \
	update-ca-certificates && \
	mkdir /app && \
	wget -O '/tmp/osticket.zip' "https://github.com/osTicket/osTicket/releases/download/v${OSTICKET_VERSION}/osTicket-v${OSTICKET_VERSION}.zip" && \
	unzip '/tmp/osticket.zip' -d /app && \
	groupadd -g "${PGID}" "${USERNAME}" && \
	useradd -u "${PUID}" -g "${PGID}" "${USERNAME}" 
COPY msmtp.conf /etc/msmtp
USER $USERNAME
EXPOSE ${HTTP_PORT}
