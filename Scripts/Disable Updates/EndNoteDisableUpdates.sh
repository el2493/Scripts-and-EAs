#!/bin/sh

cp /etc/hosts /etc/hosts.bak

echo "127.0.0.1 download.endnote.com" >> /etc/hosts

exit $?
