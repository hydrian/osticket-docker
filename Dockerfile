# syntax=docker/dockerfile:1
FROM ubuntu:22.04

ARG UID_DEFAULT 
ARG GID_DEFAULT

ENV DEBIAN_FRONTEND=noninteractive
ENV HTTP_PORT=8070 
ENV	USERNAME='osticket'
ENV OSTICKET_HOSTNAME='localhost'
ENV PHP_BASE_VERSION='8.1'
ENV TZ='UTC'
ENV OSTICKET_VERSION='1.18.1'
ENV OSTICKET_DIR='/var/www/html'
ENV OSTICKET_PLUGIN_DIR="${OSTICKET_DIR}/include/plugins"
ENV OSTICKET_PLUGIN_SRC_DIR='/usr/src/osticket-plugins'
ENV OSTICKET_PLUGINS_VERSION='develop'
ENV SUPERCRONIC_VERSION='0.2.33'
ENV INSTALL_NAME='My Helpdesk'
ENV ADMIN_FIRSTNAME='Admin'
ENV ADMIN_LASTNAME='User'
ENV ADMIN_EMAIL="${USERNAME}@${OSTICKET_HOSTNAME}"
ENV ADMIN_USERNAME='ostadmin'
ENV ADMIN_PASS='Admin1'
ENV CRON_INTERVAL=5
ENV APACHE_ERROR_LOG_FILE=/dev/stderr
ENV UID=${UID_DEFAULT}
ENV GID=${GID_DEFAULT}
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
ENV APACHE_MODS_ENABLE="php${PHP_BASE_VERSION} remoteip"
ENV APACHE_CONF_DISABLE="serve-cgi-bin"
ENV SUPERVISOR_DIR="/etc/supervisor"
ENV SUPERVISOR_CONF_FILE="${SUPERVISOR_DIR}/supervisord.conf"
ENV SUPERVISOR_PROGRAM_DIR="${SUPERVISOR_DIR}/conf.d"
ENV APACHE_RUN_USER=${USERNAME}
ENV APACHE_RUN_GROUP=${USERNAME}
ENV APACHE_PID_FILE="${APACHE_RUN_DIR}/apache2.pid"
ENV APACHE_LOCK_DIR=/var/lock/apache2
ENV APACHE_LOG_DIR=/logs/apache2
ENV APACHE_HOSTNAME="${OSTICKET_HOSTNAME}"
ENV APACHE_DEFAULT_SITE_FILE='/etc/apache2/sites-available/000-default.conf'
ENV APACHE_ERROR_LOG_FILE='/dev/stderr'
ENV USER_FILES='/var/www/user_files'



RUN \
	# Setup Timezone info
	ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
	echo $TZ > /etc/timezone && \
	# Install apt packages
	apt-get update && \
	apt-get install -y --no-install-recommends \
		git \
		nano \
		supervisor \
		ca-certificates \
		wget \
		unzip \
		msmtp \
		msmtp-mta \
		apache2 \
		"php${PHP_BASE_VERSION}" \
		"php${PHP_BASE_VERSION}-curl" \
		"php${PHP_BASE_VERSION}-cli" \
		"php${PHP_BASE_VERSION}-ldap" \
		"php${PHP_BASE_VERSION}-gd" \
		"php${PHP_BASE_VERSION}-imap" \
		"php${PHP_BASE_VERSION}-xml" \
		"php${PHP_BASE_VERSION}-mbstring" \
		"php${PHP_BASE_VERSION}-memcache" \
		"php${PHP_BASE_VERSION}-phar" \
		"php${PHP_BASE_VERSION}-intl" \
		"php${PHP_BASE_VERSION}-fileinfo" \
		"php${PHP_BASE_VERSION}-apcu" \
		"php${PHP_BASE_VERSION}-gettext" \
		"php${PHP_BASE_VERSION}-mysql" \
		"php-dompdf" \
		"php-phpseclib" \
		"php-auth-sasl" \
		"php-mail" \
		"php-net-smtp" \
		"php-net-socket" \
		"libapache2-mod-php${PHP_BASE_VERSION}"  && \
	# Setup Apache	
	for MOD in "${APACHE_MODS_DISABLE}" ; do a2dismod -f $MOD ; done  && \
	for MOD in "${APACHE_MODS_ENABLE}" ; do a2enmod $MOD ; done && \
	for CONF in "${APACHE_CONF_DISABLE}" ; do a2disconf $CONF ; done && \
	echo "Listen ${HTTP_PORT}" > "/etc/apache2/ports.conf" && \
	update-ca-certificates
COPY --chown=0:${GID_DEFAULT} supercronic.crontab /etc/crontab.supercronic
COPY --chown=0:${GID_DEFAULT} apache.conf /etc/apache2/apache2.conf
COPY --chown=0:${GID_DEFAULT} apache2-default-site.conf /etc/apache2/sites-available/000-default.conf
COPY --chown=0:${GID_DEFAULT} msmtp.conf "${MSMTP_CONF_FILE}"
COPY --chown=0:${GID_DEFAULT} supervisord.conf "${SUPERVISOR_CONF_FILE}"
COPY --chown=0:${GID_DEFAULT} supervisor-supercronic.conf "${SUPERVISOR_PROGRAM_DIR}/supercronic.conf"
COPY --chown=0:${GID_DEFAULT} supervisor-apache2.conf "${SUPERVISOR_PROGRAM_DIR}/apache2.conf"
RUN \
	# Setup SupervisorD
	groupadd -g "${GID}" "${USERNAME}" && \
	useradd -l -u "${UID}" -g "${GID}" "${USERNAME}" && \
	mkdir -p /app /run/supervisor ${APACHE_LOG_DIR} ${APACHE_RUN_DIR} ${APACHE_LOCK_DIR} && \
	find /etc/apache2  -exec chown -Rf root:${GID} \{\} \; && \
	find /etc/apache2 -type d -exec chmod -Rf 750 \{\} \; && \
	chown ${UID} ${APACHE_LOCK_DIR} ${APACHE_LOG_DIR} && \
	chgrp ${GID} /run/supervisor && \
	chmod '777' /run/supervisor && \
	# Setup msmtp
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
	# Setup SuperCronic
	wget -O '/usr/local/bin/supercronic' "https://github.com/aptible/supercronic/releases/download/v${SUPERCRONIC_VERSION}/supercronic-linux-amd64" && \
	chmod +x /usr/local/bin/supercronic && \
	# Setup Official OSTicket
	wget -O '/tmp/osticket.zip' "https://github.com/osTicket/osTicket/releases/download/v${OSTICKET_VERSION}/osTicket-v${OSTICKET_VERSION}.zip" && \
	unzip '/tmp/osticket.zip' -d /var/www && \
	rm '/tmp/osticket.zip' && \
	rm -Rf /var/www/html && \
	mv /var/www/upload/ /var/www/html && \
	# Setup Official Plugins
    git clone --branch "${OSTICKET_PLUGINS_VERSION}" "https://github.com/osTicket/osTicket-plugins.git" "${OSTICKET_PLUGIN_SRC_DIR}" && \
	cd "${OSTICKET_PLUGIN_SRC_DIR}" \
    php make.php hydrate && \
    for plugin in $(find * -maxdepth 0 -type d ! -path doc ! -path lib); do cp -r "${plugin}" "${OSTICKET_PLUGIN_DIR}"; done; \
    #cp -R ${OSTICKET_PLUGIN_SRC_DIR}/*.phar "${OSTICKET_PLUGIN_DIR}/" && \
    cd / && \
	## Archiver
	if  ( ${COMMUNITY_PLUGINS} ) ; then \
		git clone --branch master https://github.com/clonemeagain/osticket-plugin-archiver ${OSTICKET_PLUGIN_DIR}/archiver && \
		## Attachment Preview
		git clone --branch master https://github.com/clonemeagain/attachment_preview ${OSTICKET_PLUGIN_DIR}/attachment-preview && \
		## Auto Closer
		git clone --branch master https://github.com/clonemeagain/plugin-autocloser  ${OSTICKET_PLUGIN_DIR}/auto-closer && \
		## Fetch Note
		git clone --branch master https://github.com/bkonetzny/osticket-fetch-note ${OSTICKET_PLUGIN_DIR}/fetch-note && \
		## Field Radio Buttons
		git clone --branch master https://github.com/Micke1101/OSTicket-plugin-field-radiobuttons  ${OSTICKET_PLUGIN_DIR}/field-radiobuttons && \
		## Mentioner
		git clone --branch master https://github.com/clonemeagain/osticket-plugin-mentioner ${OSTICKET_PLUGIN_DIR}/mentioner && \
		## Multi LDAP Auth
		git clone --branch master https://github.com/philbertphotos/osticket-multildap-auth ${OSTICKET_PLUGIN_DIR}/multi-ldap && \
		mv ${OSTICKET_PLUGIN_DIR}/multi-ldap/multi-ldap/* ${OSTICKET_PLUGIN_DIR}/multi-ldap/ && \
		rm -rf ${OSTICKET_PLUGIN_DIR}/multi-ldap/multi-ldap && \
		## Prevent Autoscroll
		git clone --branch master https://github.com/clonemeagain/osticket-plugin-preventautoscroll ${OSTICKET_PLUGIN_DIR}/prevent-autoscroll && \
		## Rewriter
		git clone --branch master https://github.com/clonemeagain/plugin-fwd-rewriter ${OSTICKET_PLUGIN_DIR}/rewriter && \
		## Slack
		git clone --branch master https://github.com/clonemeagain/osticket-slack ${OSTICKET_PLUGIN_DIR}/slack && \
		## Teams (Microsoft)
		git clone --branch master https://github.com/ipavlovi/osTicket-Microsoft-Teams-plugin ${OSTICKET_PLUGIN_DIR}/teams ; \
	fi && \	
	export CRON_SCRIPT="/var/www/scripts/rcron.php" && \
	chmod -R +x "/var/www/scripts" && \
	sed -ir 's|http://yourdomain.com/support|http://localhost|' "${CRON_SCRIPT}" && \
	chown ${UID} "/var/lib/php/sessions" && \
	export OST_CONFIG_FILE='/var/www/html/include/ost-config.php' && \
	test '!' -e "${OST_CONFIG_FILE}" && cp "/var/www/html/include/ost-sampleconfig.php" "${OST_CONFIG_FILE}" && \
	chown ${UID} "${OST_CONFIG_FILE}" && \
	mkdir "${USER_FILES}" && \
	chown ${UID}:${GID} "${USER_FILES}" && \ 
	chmod 1770 /tmp && \
	chown root:${GID} /tmp 
RUN \
	sed -ir 's|%OSTICKET_ADMIN_EMAIL%|'"${ADMIN_EMAIL}"'|' "${APACHE_DEFAULT_SITE_FILE}" && \
	sed -ir 's|%APACHE_HOSTNAME%|'"${OSTICKET_HOSTNAME}"'|' "${SUPERVISOR_CONF_FILE}" && \
	sed -ir 's|%APACHE_LOG_DIR%|'"${APACHE_LOG_DIR}"'|' "${APACHE_DEFAULT_SITE_FILE}"  && \
	sed -ir 's|%HTTP_PORT%|'"${HTTP_PORT}"'|' "${APACHE_DEFAULT_SITE_FILE}" && \
	sed -ir 's|%CRON_INTERVAL%|'"${CRON_INTERVAL}"'|' "/etc/crontab.supercronic" && \
	a2ensite 000-default
USER $USERNAME
ENTRYPOINT ["/usr/bin/supervisord"]
EXPOSE ${HTTP_PORT}
