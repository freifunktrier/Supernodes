#!/bin/sh
if ! ping -c 5 10.207.0.220; then
if ! ping -c 5 10.207.6; then
service tinc restart
fi
fi