#!/usr/bin/env bash

TARGET_FS="$1"
MAILTO="$2"

/bin/findmnt --mtab --target ${TARGET_FS} > /dev/null 2>&1

if [ "$?" -ne 0 ]; then
  echo "Mounting ${TARGET_FS}..."
  /bin/mount --target ${TARGET_FS} > /dev/null 2>&1
  if [ "$?" -ne 0 ]; then
    echo "Mount unsuccessful. Sending mount list to ${MAILTO}..."
    /bin/findmnt | /usr/bin/mail -s "Filesystem ${TARGET_FS} not mounted" ${MAILTO}
  fi
else
  echo "${TARGET_FS} is already mounted"
fi
