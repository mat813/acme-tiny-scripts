#!/bin/sh

# default values
lets_private=/etc/ssl/private/letsencrypt
lets_public=/etc/ssl/public/letsencrypt
challenges=/usr/local/www/challenges
ssl_config=/etc/ssl/openssl.cnf

critical=10
warning=15
renew=20

. "${dir}"/config.sh

caller=$(basename "$0")
my_id=$(id -u)

if [ ! -d "${lets_private}" ]
then
	echo "Private directory does not exist. You need to run, as root:"
	echo "install -d -o ${my_id} -g 0 -m 0711 ${lets_private}"
	ret=1
elif [ "${caller}" != "check_expire.sh" -a ! -w "${lets_private}" ]
then
	echo "The private directory is not writable, as root, run:"
	echo "chown ${my_id} ${lets_private}"
	echo "chmod 0711 ${lets_private}"
fi

if [ ! -d "${lets_public}" ]
then
	echo "Public directory does not exist. You need to run, as root:"
	echo "install -d -o ${my_id} -g 0 -m 0755 ${lets_public}"
	ret=1
elif [ "${caller}" != "check_expire.sh" -a ! -w "${lets_public}" ]
then
	echo "The public directory is not writable, as root, run:"
	echo "chown ${my_id} ${lets_public}"
	echo "chmod 0755 ${lets_public}"
fi

if [ ! -d "${challenges}" ]
then
	echo "Challenge directory does not exist. You need to run, as root:"
	echo "install -d -o ${my_id} -g 0 -m 0755 ${challenges}"
	ret=1
elif [ "${caller}" != "check_expire.sh" -a ! -w "${challenges}" ]
then
	echo "The challenge directory is not writable, as root, run:"
	echo "chown ${my_id} ${challenges}"
	echo "chmod 0755 ${challenges}"
fi

if [ ! -e "${ssl_config}" ]
then
	echo "The openssl.cnf config file does not exist at ${ssl_config}."
	echo "Please, edit the lets_path.sh file and point it to an existing one."
	ret=1
fi

if [ -n "${ret}" ]
then
	exit 1
fi
