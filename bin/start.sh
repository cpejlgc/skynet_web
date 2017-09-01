#!/bin/sh

export ROOT=$(pwd)

export DAEMON=false
export LOG_PATH='"./logs/"'
while getopts "DKUl:" arg
do
    case $arg in
        D)
            export DAEMON=true
            ;;
        K)
            kill `cat $ROOT/run/skynet.pid`
            exit 0;
            ;;
        l)
            export LOG_PATH='"'$OPTARG'"'
            ;;
        U)
            echo 'start srv_hotfix' | nc 127.0.0.1 8000
            exit 0;
            ;;
    esac
done

$ROOT/skynet/skynet $ROOT/etc/config.lua
