#!/bin/bash

# get environment variables
source /etc/container_environment.sh

VESTA_PATH='/usr/local/vesta'
domain='$VESTA_DOMAIN'
user='admin'

# only run if domain has a value
if [ -n "$domain" ] ; then
    # too often, user did not setup DNS host to IP correctly, so we should validate first
    # issue is easier fix by the user than getting blocked by Letsencrypt server
    #
    # validate that the domain matches the IP

    # get the ip
    DOMAINIP=$( dig +short ${domain}  | grep -v "\.$" | head -n 1 )
    MYIP=$( dig +short myip.opendns.com @resolver1.opendns.com | grep -v "\.$" | head -n 1 )

    # create the website under admin for Letsencrypt SSL
    if [[ $DOMAINIP != $MYIP ]]; then
    	echo "[err] Domain '$domain' IP '$DOMAINIP' does not match Host IP '$MYIP'"

        exit 1
    fi

    # wait for any web service to start first (nginx, apache, vesta, etc...)
    # since letsencrypt need to hit and validate
    sleep 5

    cert_src="/home/${user}/conf/web/ssl.${domain}.pem"
    key_src="/home/${user}/conf/web/ssl.${domain}.key"

    cert_dst="/usr/local/vesta/ssl/certificate.crt"
    key_dst="/usr/local/vesta/ssl/certificate.key"

    # if no letsencrypt domain under $user, create one
    if [ ! -f "$cert_src" ]; then
    	echo "[i] Creating '$user' website for '$domain'"

    	$VESTA_PATH/bin/v-add-letsencrypt-domain '$user' '$domain' '' 'no'

        # wait for letsencrypt to complete
        # a better check would be for the existence of $cert_src with x retries
        sleep 5
    fi

    if ! cmp -s $cert_dst $cert_src
    then
        # backup the old cert
        cp -fn $cert_dst "$cert_dst.bak"
        cp -fn $key_dst "$key_dst.bak"

        # link the new cert
    	ln -sf $cert_src $cert_dst
    	ln -sf $key_src $key_dst

        # Change Permission
        chown root:mail $cert_dst
        chown root:mail $key_dst

        # Let the user restart the service by themself
        # service vesta restart &> /dev/null
        # service exim4 restart &> /dev/null
        echo "[i] Cert file successfullly swapped out.  Please restart vesta, apache2, nginx, and exim4."
    fi

    echo "[i] If everything went fine. Your certificate is ready: https://$domain:8083"
fi
