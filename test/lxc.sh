#!/bin/bash

function lxc_create
{
  local _NAME="$1"
  local _DISTRO="$2"
  local _RELEASE="$3"

  lxc-create -t download -n ${_NAME} -- -d ${DISTRO} -r ${RELEASE} -a armhf
  return $?
}

function lxc_state
{
  local _NAME="$1"
  local _INFO=$(lxc-info -n ${_NAME} --state)
  echo "${_INFO}" | awk '/^State:\w*(.*)$/ { print $2 }'
}

function lxc_ip
{
  local _NAME="$1"
  local _INFO=$(lxc-info -n ${_NAME} --ip)
  echo "${_INFO}" | awk ' /^IP:\w*(.*)$/ { print $2 }'
}

function lxc_info
{
  local _NAME="$1"
  lxc-info -n ${_NAME}
}

function lxc_start
{
  local _NAME="$1"
  lxc-start -n ${_NAME} -d
  return $?
}

function up
{
  DISTRO="$1"
  RELEASE="$2"

  if [ ! -e "$HOME/.mist" ]
  then
    mkdir -p "$HOME/.mist"
  fi

  if [ -e "$HOME/.mist/lxc-sequence" ]
  then
    SEQUENCE=$(cat "$HOME/.mist/lxc-sequence")
  else
    SEQUENCE=1
  fi

  NAME="build${SEQUENCE}"
  let SEQUENCE=$SEQUENCE+1
  echo $SEQUENCE > "$HOME/.mist/lxc-sequence"

  lxc_create "$NAME" "$DISTRO" "$RELEASE"
  RC=$?
  if [ $RC -ne 0 ]
  then
    echo "Failed to create container" >&2
    exit 1
  fi

  STATE=$(lxc_state "$NAME")
  if (( $STATE != "STOPPED" ))
  then
    echo "Container created but state is ${STATE}: expected STOPPED!" >&2
    exit 1
  fi

  lxc_start "$NAME"
  RC=$?
  if [ $RC -ne 0 ]
  then
    echo "Failed to start ${NAME}"
    # XXX Clean up
    exit 1
  fi

  echo "Waiting for container to start..."
  while (( $STATE != "RUNNING" ))
  do
    STATE=$(lxc_state "$NAME")
    sleep 1
  done

  echo "Waiting for network..."
  IP=$(lxc_ip "$NAME")
  while [ -z $IP ]
  do
    IP=$(lxc_ip "$NAME")
    sleep 1
  done

  echo "$NAME:$STATE:$IP"
}

function prepare
{
  local _NAME=$1

  # XXX This is the same key as the 'build' user on the hosts, and should be different.
  KEY='ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC+5gRu20uN7DWPS/KIZgFotUtkE+fXoxU1W76s+wpfZ50KnFwV51S/FiwXyzfvVoeGos2+prQLbfGhlpMtnUcihlpITbPcUrXsWYhwmeJVC+sNGkirXJJx5RCie4pmxnLesMYBP3regmpWWEkSEYTwVOV2dn9WIyhuQbhRSe6jEVhPbz21hOEcGyDb7Wx9L75lent2dklAFToZHp4BJSkA5w4hNeQIXTeMWWUDMmRnjSu9zz76TMoN51N6nWtwzzsr9/9ajJFHLkxl7M10r9H/Ei+eRkeauU8vT+j5sBNSpcHSv6AnsRrm8O9uOnWwXlXQA3Ggl1CcWvjXC5qTlGfr kristian@Kristians-MacBook-Pro.local'

  lxc-attach -n ${_NAME} -- apt-get update 
  lxc-attach -n ${_NAME} -- apt-get install -y openssh-server
  lxc-attach -n ${_NAME} -- useradd -m -s /bin/bash build
  lxc-attach -n ${_NAME} -- mkdir -p /home/build/.ssh
  lxc-attach -n ${_NAME} -- chmod 0700 /home/build/.ssh
  lxc-attach -n ${_NAME} -- sh -c 'echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC+5gRu20uN7DWPS/KIZgFotUtkE+fXoxU1W76s+wpfZ50KnFwV51S/FiwXyzfvVoeGos2+prQLbfGhlpMtnUcihlpITbPcUrXsWYhwmeJVC+sNGkirXJJx5RCie4pmxnLesMYBP3regmpWWEkSEYTwVOV2dn9WIyhuQbhRSe6jEVhPbz21hOEcGyDb7Wx9L75lent2dklAFToZHp4BJSkA5w4hNeQIXTeMWWUDMmRnjSu9zz76TMoN51N6nWtwzzsr9/9ajJFHLkxl7M10r9H/Ei+eRkeauU8vT+j5sBNSpcHSv6AnsRrm8O9uOnWwXlXQA3Ggl1CcWvjXC5qTlGfr kristian@Kristians-MacBook-Pro.local" > /home/build/.ssh/authorized_keys'
  lxc-attach -n ${_NAME} -- chmod 0600 /home/build/.ssh/authorized_keys
  lxc-attach -n ${_NAME} -- chown -R build:build /home/build/.ssh
}

function lxc_stop
{
  local _NAME=$1
  lxc-stop -n ${_NAME}
  return $?
}

function lxc_destroy
{
  local _NAME=$1
  lxc-destroy -n ${_NAME}
  return $?
}

function down
{
  local _NAME=$1
  lxc_stop $_NAME
  if [ $? -ne 0 ]
  then
    echo "Failed to stop container; will continue" >&2
  fi

  lxc_destroy $_NAME
  if [ $? -ne 0 ]
  then
    echo "Failed to destroy container" >&2
    exit 1
  fi
}

function info
{
  local _NAME=$1
  STATE=$(lxc_state "$_NAME")
  IP=$(lxc_ip "$_NAME")
  echo "$_NAME:$STATE:$IP"
}

ACTION=''
while getopts "updi" OPT
do
  case $OPT in
    u)
      ACTION="up"
      ;;
    p)
      ACTION="prepare"
      ;;
    d)
      ACTION="down"
      ;;
    i)
      ACTION="info"
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      ;;
  esac
done

shift $(($OPTIND - 1))

case $ACTION in
  up)
    up $1 $2
    ;;
  prepare)
    prepare $1
    ;;
  down)
    down $1
    ;;
  info)
    info $1
    ;;
esac
