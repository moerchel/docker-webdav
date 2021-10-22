#!/bin/bash

if [[ -n "$USERNAME" ]] && [[ -n "$PASSWORD" ]]
then
        htpasswd -bc /etc/nginx/htpasswd $USERNAME $PASSWORD
        echo Done setting user and password...
else
    echo Not using authentication...
        sed -i 's%auth_basic "Restricted";% %g' /etc/nginx/conf.d/default.conf
        sed -i 's%auth_basic_user_file /etc/nginx/htpasswd;% %g' /etc/nginx/conf.d/default.conf
fi

service cron start
