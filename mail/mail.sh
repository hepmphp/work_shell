#/bin/bash

yum install mailx

echo "set from=hepanming007@126.com set smtp=smtp.126.com   set smtp-auth-user=hepanming007 set smtp-auth-password=He199033028 set smtp-auth=login 
" >>/etc/mail.rc