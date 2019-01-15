#
# dump postgresql database of mastodon.
#
MKDIR_CMD='/bin/mkdir'
LOGGER_CMD='/usr/bin/logger'
SUDO_CMD='/usr/bin/sudo'
FIND_CMD='/usr/bin/find'

SCRIPT_DIR=$(cd $(dirname $0); pwd)
source ${SCRIPT_DIR}/.env.backup-postgresql

# check argument
if [[ "${1}" = "" ]]; then
  echo "Usage: ${0} <backup destination directory>"
  ${LOGGER_CMD} -p user.err 'argument error.'
  exit 1
fi
BACKUP_DEST_DIR=${1}


# check backup destination directory
if [[ ! -d "${BACKUP_DEST_DIR}" ]] || [[ ! -w "${BACKUP_DEST_DIR}" ]]; then
  echo "cannot write dump file to destination directory: ${BACKUP_DEST_DIR}"
  ${LOGGER_CMD} -p user.err "cannot write dump file to destination directory: ${BACKUP_DEST_DIR}"
  exit 1
fi

# set dump file name
LANG_=${LANG}
export LANG=en_US.utf8
DUMP_FILE="${BACKUP_DEST_DIR}/${DB_NAME}.dump.$(date +%Y-%m-%d-%H.%M.%S)"
export LANG=${LANG_}

if [[ "${DB_HOST}" =~ ^/ ]]; then
  cd /var/tmp # to avoid a warning "permission denied"
  ${SUDO_CMD} -u ${DB_USER} ${PG_DUMP} -Fc -d ${DB_NAME} --schema=public > ${DUMP_FILE}
else
  ${PG_DUMP} -Fc -w -h ${DB_HOST} -d ${DB_NAME} -U ${DB_USER} --schema=public > ${DUMP_FILE}
fi

if [[ $? -ne 0 ]]; then
  echo 'failed to dump postgresql database.'
  ${LOGGER_CMD} -p user.err 'failed to dump postgresql database.'
  exit 2
fi

# delete old dump files
${FIND_CMD} ${BACKUP_DEST_DIR} -name "${DB_NAME}.dump.*" -mtime +${NUM_DAYS} -exec rm {} \;
if [[ $? -ne 0 ]]; then
  echo 'failed to delete old dump files.'
  ${LOGGER_CMD} -p user.err 'failed to delete old dump files.'
  exit 3
fi

# generate restore commands
RESTORE_TXT="${BACKUP_DEST_DIR}/restore.txt"

if [[ "${DB_HOST}" =~ ^/ ]]; then
  echo "# cd /var/tmp"
  echo "# sudo -u ${DB_USER} psql -d postgres" > ${RESTORE_TXT}
else
  echo "# psql -h ${DB_HOST} -d postgres -U ${DB_USER} -W" > ${RESTORE_TXT}
  echo "Password for user ${DB_USER}: <enter password (check .env.production)>" >> ${RESTORE_TXT}
fi

echo "postgres=> drop database ${DB_NAME};" >> ${RESTORE_TXT}
echo "postgres=> create database ${DB_NAME};" >> ${RESTORE_TXT}
echo "postgres=> \q" >> ${RESTORE_TXT}

if [[ "${DB_HOST}" =~ ^/ ]]; then
  echo "# sudo -u ${DB_USER} pg_restore -Fc -h ${DB_HOST} -d ${DB_NAME} ${DUMP_FILE}" >> ${RESTORE_TXT}
  echo "# sudo -u postgres psql -d ${DB_NAME}" >> ${RESTORE_TXT}
  echo "${DB_NAME}=# create extension pg_stat_statements;" >> ${RESTORE_TXT}
  echo "${DB_NAME}=# \q" >> ${RESTORE_TXT}
else
  echo "# pg_restore -Fc -h ${DB_HOST} -d ${DB_NAME} -U ${DB_USER} ${DUMP_FILE}" >> ${RESTORE_TXT}
  echo "# psql -h ${DB_HOST} -d ${DB_NAME} -U postgres -W" >> ${RESTORE_TXT}
  echo "Password for user postgres: <enter password>" >> ${RESTORE_TXT}
  echo "${DB_NAME}=# create extension pg_stat_statements;" >> ${RESTORE_TXT}
  echo "${DB_NAME}=# \q" >> ${RESTORE_TXT}
fi

exit 0
