#!/bin/sh
if ! ping -c 5 10.207.0.220; then
if ! ping -c 5 10.207.0.6; then
logger Oh crap! Need to restart tinc now.
service tinc restart
fi
fi