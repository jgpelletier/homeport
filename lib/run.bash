#!/bin/bash

set -e

homeport module <<-usage
    usage: homeport run
usage

trap cleanup EXIT SIGTERM SIGINT

function cleanup() {
    local pids=$(jobs -pr)
    [ -n "$pids" ] && kill $pids
}

ssh_options=''
docker_options=''

declare argv
argv=$(getopt --options +v:p:Ad --long docker,volumes-from:,link:,name: -- "$@") || exit 1
eval "set -- $argv"

homeport_tag=default
homeport_unix_user=$USER

docker_rm=1 named=0 daemonize=0

while true; do
    case "$1" in
        --docker)
            if which boot2docker > /dev/null; then
                host_docker="/usr/local/bin/docker"
            else
                host_docker=$(which docker)
            fi
            docker_options+="-v $host_docker:$host_docker:ro "
            docker_options+='-v /var/run/docker.sock:/var/run/docker.sock:rw '
            docker_options+="-e HOMEPORT_DOCKER_IMAGE_NAME=$homeport_image_name "
            shift
            ;;
        -d)
            daemonize=1
            docker_options+="$1"' '
            shift
            ;;
        -v | -p | --volumes-from | --link | --name)
            case "$1" in
                --name)
                    named=1
                    ;;
            esac
            docker_options+="$1"' '"$2"' '
            shift
            shift
            ;;
        -A)
            ssh_options+="$1"' '
            docker_options+='-v $(readlink -f $SSH_AUTH_SOCK):/home/'$homeport_unix_user/.ssh-agent' '
            docker_options+='-e SSH_AUTH_SOCK=/home/'$homeport_unix_user'/.ssh-agent '
            shift
            ;;
        --)
            shift
            break
            ;;
    esac
done

docker='docker run '
docker+='-u '$homeport_unix_user' '
docker+='--volumes-from '$homeport_home_volume' '
docker+='-h homeport '
if [ "$named" -ne 1 -a "$daemonize" -ne 1 ]; then
    docker+='--rm '
fi
if [ "$daemonize" -ne 1 ]; then
    docker+='-it '
    ssh_options+='-t '
fi
docker+=$docker_options
docker+=$homeport_image_name

if [ $# -eq 0 ]; then
    docker+=' /home/'$homeport_unix_user'/.homeportrc'
else
    while [ $# -ne 0 ]; do
        docker+=' '$(printf '%q' "$1")
        shift
    done
fi

if which boot2docker > /dev/null; then
   echo boot2docker ssh $ssh_options sh -c $(printf '%q' "$docker")
else
   echo $docker
fi
