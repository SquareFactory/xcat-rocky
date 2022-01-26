#!/bin/bash

setsid ./entrypoint.sh &

exec /sbin/init
