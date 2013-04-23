#!/bin/bash
KEYTABLE=/etc/opendkim/KeyTable
SIGNTABLE=/etc/opendkim/SigningTable
KEYDIR=/etc/opendkim/keys
SELECTOR='mail'

OPENDKIM_USER=opendkim
OPENDKIM_GROUP=opendkim
OPENDKIM_KEYLENGTH=1024

DOMAIN=$1
if [ ! $DOMAIN ]; then
  echo "$0 [domainname.tld]"
  exit 1
fi
ping -c1 $DOMAIN 2>&1 >/dev/null
if [ $? -ne 0 ];then
  echo "please make sure the domain is valid and reachable via ICMP type 8"
fi

# create entry in signtable
ENTRY="$DOMAIN\t$SELECTOR._domainkey.$DOMAIN\n"
grep "$DOMAIN" $SIGNTABLE >/dev/null
if [ $? -eq 1 ]; then
  echo 'adding '$DOMAIN' to signtable'
  printf $ENTRY >> $SIGNTABLE
else
  echo entry for $DOMAIN already exists in $SIGNTABLE: skipping
fi

#create entry in keytable
ENTRY="$SELECTOR._domainkey.$DOMAIN\t$DOMAIN:$SELECTOR:$KEYDIR/$DOMAIN/$SELECTOR.private\n"
grep "$SELECTOR._domainkey.$DOMAIN" $KEYTABLE >/dev/null
if [ $? -eq 1 ]; then
  echo 'adding '$DOMAIN' to keytable'
  printf $ENTRY >> $KEYTABLE
else
  echo entry for $DOMAIN already exists in $KEYTABLE: skipping
fi

if [ ! -d $KEYDIR/$DOMAIN ]; then
  mkdir -p $KEYDIR/$DOMAIN
else
  if [ $(ls -la $KEYDIR/$DOMAIN/ | head -n1 | awk '{print $2}') -ne 0 ]; then
    echo "[WARN] found previously generated key, please remove by hand if you still want to proceed!"
    exit 1
  fi
fi

# generate keys
opendkim-genkey -b "$OPENDKIM_KEYLENGTH" -d "$DOMAIN" -D "$KEYDIR/$DOMAIN" -r -s "$SELECTOR"
if [ $? -ne 0 ]; then
  echo "an error occured generating the keys... exiting" 
  exit 1 
fi
chown $OPENDKIM_USER.$OPENDKIM_GROUP $KEYDIR/$DOMAIN/$SELECTOR.private
chmod 600 $KEYDIR/$DOMAIN/$SELECTOR.private
echo "now please put the following string into your DNS config:"
MXIP=$(dig +short `dig +short $DOMAIN mx | awk '{print $2}'`)
printf "\n=================\n$DOMAIN IN TXT v=spf1 ip4:$MXIP ~all\n"
cat $KEYDIR/$DOMAIN/$SELECTOR.txt
printf '=================\n'

#restarting opendkim
/etc/init.d/opendkim restart
