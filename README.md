dkim_autodeploy
===============

DKIM AutoDeploy needs some packages to work:

    aptitude install dnsutils opendkim

Hint: a standard debian postfix lies in a chroot env under ```/var/spool/postfix```. Therefore you may want to do the following:

  * set /var/spool/postfix/opendkim.sock as the socket location in opendkim.conf
  * ```chown 777 /var/spool/postfix/opendkim.sock``` to make the socket writable for postfix (unfortunately there is no user/group policy to set)

