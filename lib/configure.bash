#!/bin/bash

set -e

homeport module <<-usage
    usage: homeport configure --user [version] --account [Docker Hub account]

    description:

        Creates a configuration that stores the user name in a data container
        for use with all Homeport Create a configuration file in a volume named
        "/etc/data container named "homeport_configuration" for use with
        homeport.
usage

declare argv
argv=$(getopt -o u:a: --long user:,account: -- "$@") || return
eval "set -- $argv"

while true; do
    case "$1" in
        --user | -u)
            shift
            user=$1
            shift
            ;;
        --account | -a)
            shift
            account=$1
            shift
            ;;
        --)
            shift
            break
            ;;
    esac
done

if ! { docker images | awk '{ print $1 }' | grep '^'$account'/jq$' > /dev/null; } then
    echo exists
fi
docker run --rm ubuntu echo 1

cat <<EOF > ~/.homeport
homeport_unix_user=$user
homeport_docker_account=$account
EOF
