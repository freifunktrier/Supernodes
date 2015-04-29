#!/bin/sh
if ! ping -c 5 10.207.0.220; then
if ! ping -c 5 10.207.0.6; then
logger Oh crap! Need to restart tinc now.
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
service tinc restart
fi
fi