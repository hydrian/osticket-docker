# syntax=docker/dockerfile:1
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV HTTP_PORT=8070 
ENV	USERNAME='osticket'
ENV PHP_BASE_VERSION='8.1'
ENV TZ='UTC'
ENV OSTICKET_VERSION='1.18.1'
ENV APACHE_ERROR_LOG_FILE=/dev/stderr
ENV PUID=1000
ENV PGID=1000
ENV OSTICKET_HOSTNAME='localhost'
ENV MSMTP_CONF_FILE='/etc/msmtprc'
ENV SMTP_HOSTNAME='localhost'
ENV SMTP_PORT='465'
ENV SMTP_TLS='on'
ENV SMTP_STARTTLS='off'
ENV SMTP_CERTCHECK='on'
ENV SMTP_LOGIN='on'
ENV SMTP_USER='osticket'
ENV SMTP_PASS='changeme'
ENV SMTP_FROM="osticket@${OSTICKET_HOSTNAME}"
ENV SMTP_TRUST_FILE='/etc/ssl/certs/ca-certificates.crt'
ENV APACHE_MODS_DISABLE='status autoindex'
ENV APACHE_MODS_ENABLE="php${PHP_BASE_VERSION}"
ENV APACHE_CONF_DISABLE="serve-cgi-bin"
ENV SUPERVISOR_CONF_FILE="/etc/supervisord.conf"
ENV APACHE_RUN_USER=${USERNAME}
ENV APACHE_RUN_GROUP=${USERNAME}
ENV APACHE_RUN_DIR=/var/run/apache2
ENV APACHE_PID_FILE="${APACHE_RUN_DIR}/apache2.pid"
ENV APACHE_LOCK_DIR=/var/lock/apache2
ENV APACHE_LOG_DIR=/log/apache2
ENV APACHE_HOSTNAME="${OSTICKET_HOSTNAME}"
COPY msmtp.conf "${MSMTP_CONF_FILE}"
COPY supervisord.conf "${SUPERVISOR_CONF_FILE}"

RUN \
	ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
	echo $TZ > /etc/timezone && \
	apt-get update && \
	apt-get install -y --no-install-recommends \
		nano \
		supervisor \
		ca-certificates \
		wget \
		unzip \
		msmtp \
		msmtp-mta \
		apache2 \
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
	for MOD in "${APACHE_MODS_DISABLE}" ; do a2dismod -f $MOD ; done  && \
	for MOD in "${APACHE_MODS_ENABLE}" ; do a2enmod $MOD ; done && \
	for CONF in "${APACHE_CONF_DISABLE}" ; do a2disconf $CONF ; done && \
	echo "Listen ${HTTP_PORT}" > "/etc/apache2/ports.conf" && \
	find /etc/apache2 -type d -exec chown -Rf root:${PGID} \{\} \; && \
	find /etc/apache2 -type f -exec chmod -Rf 750 \{\} \; && \
	update-ca-certificates && \
	mkdir -p /app /run/supervisor ${APACHE_LOG_DIR} ${APACHE_RUN_DIR} ${APACHE_LOCK_DIR} && \
	chown ${PUID} ${APACHE_LOCK_DIR} ${APACHE_LOG_DIR} ${APACHE_RUN_DIR} && \
	chgrp ${PGID} /run/supervisor && \
	chmod '770' /run/supervisor && \
	sed -ir 's|youruser|'"${PUID}"':'"${PGID}"'|' "${SUPERVISOR_CONF_FILE}" && \
	sed -ir 's|%SMTP_HOSTNAME%|'"${SMTP_HOSTNAME}"'|' "${MSMTP_CONF_FILE}" && \
	sed -ir 's|%SMTP_PORT%|'"${SMTP_PORT}"'|' "${MSMTP_CONF_FILE}" && \
	sed -ir 's|%SMTP_TLS%|'"${SMTP_TLS}"'|' "${MSMTP_CONF_FILE}" && \
	sed -ir 's|%SMTP_STARTTLS%|'"${SMTP_STARTTLS}"'|' "${MSMTP_CONF_FILE}" && \
	sed -ir 's|%SMTP_CERTCHECK%|'"${SMTP_CERTCHECK}"'|' "${MSMTP_CONF_FILE}" && \
	sed -ir 's|%SMTP_TRUST_FILE%|'"${SMTP_TRUST_FILE}"'|' "${MSMTP_CONF_FILE}" && \
	sed -ir 's|%SMTP_LOGIN%|'"${SMTP_LOGIN}"'|' "${MSMTP_CONF_FILE}" && \
	sed -ir 's|%SMTP_USER%|'"${SMTP_USER}"'|' "${MSMTP_CONF_FILE}" && \
	sed -ir 's|%SMTP_PASS%|'"${SMTP_PASS}"'|' "${MSMTP_CONF_FILE}" && \
	sed -ir 's|%SMTP_FROM%|'"${SMTP_FROM}"'|' "${MSMTP_CONF_FILE}" && \
	wget -O '/tmp/osticket.zip' "https://github.com/osTicket/osTicket/releases/download/v${OSTICKET_VERSION}/osTicket-v${OSTICKET_VERSION}.zip" && \
	unzip '/tmp/osticket.zip' -d /var/www && \
	groupadd -g "${PGID}" "${USERNAME}" && \
	useradd -u "${PUID}" -g "${PGID}" "${USERNAME}" 
COPY apache.conf /etc/apache2/apache2.conf
USER $USERNAME
#ENTRYPOINT ["/usr/bin/supervisord"]
EXPOSE ${HTTP_PORT}
