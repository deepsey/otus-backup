#!/bin/bash

#Server name

BORG_SERVER=otus-bkps

# Backup type, it may be data, system, mysql, binlogs, etc.

TYPE_OF_BACKUP=etc

REPOSITORY="${BORG_SERVER}:/var/backup/$(hostname)-${TYPE_OF_BACKUP}"

#Create backup

borg create --list -v --stats \
 $REPOSITORY::"etc-{now:%Y-%m-%d-%H-%M}" \
 /etc
 
#Prune old backup

borg prune -v --list \
    --keep-within=7d \
    --keep-weekly=4 \
    $REPOSITORY
