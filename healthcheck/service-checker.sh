#!/bin/sh

set -e
set -u

RETRY_DELAY=5
RETRY_COUNT_MAX=10
RETRY_COUNTER=0

for i in "$@"; do
  case $i in
    --delay=*)
      RETRY_DELAY=${i#--delay=}
      shift
      ;;
    --max=*)
      RETRY_COUNT_MAX=${i#--max=}
      shift
      ;;
    *)
      SERVICE_CONTAINER_NAME=$1
      ;;
  esac
done

[ -z "${SERVICE_CONTAINER_NAME}" ] && {
    echo "SERVICE_CONTAINER_NAME argument is required"
    exit 1
}

echo "Checking if service container ${SERVICE_CONTAINER_NAME} is healthy (delay = ${RETRY_DELAY}, max = ${RETRY_COUNT_MAX})"

while [ -z `docker ps -q -f name=${SERVICE_CONTAINER_NAME} -f health=healthy` ]; do
    RETRY_COUNTER=$(($RETRY_COUNTER+1))
    echo "Try ${RETRY_COUNTER}/${RETRY_COUNT_MAX}... "
    
    sleep ${RETRY_DELAY}
    echo "waiting ${RETRY_DELAY}s"
    
    if [ -n "`docker ps -q -f name=${SERVICE_CONTAINER_NAME} -f status=exited`" ]
	then
		echo "Container ${SERVICE_CONTAINER_NAME} is down"
		exit 1
	fi
    
    if [ $RETRY_COUNTER = $RETRY_COUNT_MAX ]
    then
        echo "Max tries reached (${RETRY_COUNT_MAX}) !"
        exit 1
    fi

    echo "service is not healthy yet !"
    
done

echo "Service container ${SERVICE_CONTAINER_NAME} is healthy"
