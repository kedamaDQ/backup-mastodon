#
# dump redis database of mastodon.
#
RETRY=3
MKDIR_CMD='/bin/mkdir'
CP_CMD='/bin/cp'
FIND_CMD='/usr/bin/find'
LOGGER_CMD='/usr/bin/logger'

SCRIPT_DIR=$(cd $(dirname $0); pwd)
source ${SCRIPT_DIR}/.env.backup-redis

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

LAST_TS=$(${REDIS_CLI} lastsave)

${REDIS_CLI} bgsave
if [[ $? != 0 ]]; then
  echo 'failed to dump redis database.'
  ${LOGGER_CMD} -p user.err 'failed to dump redis database.'
  exit 2
fi


while [[ "${LAST_TS}" = $(${REDIS_CLI} lastsave) ]] && [[ ${RETRY} -ne 0 ]]; do
  sleep 10
  let RETRY=RETRY-1
done

if [[ "${LAST_TS}" = $(${REDIS_CLI} lastsave) ]]; then
  echo 'failed to backup redis data: timeout'
  ${LOGGER_CMD} -p user.err 'failed to backup redis data: timeout'
  exit 3
fi

LANG_=${LANG}
export LANG=en_US.utf8
DUMP_FILE="${BACKUP_DEST_DIR}/dump.rdb.$(date --date "@$(${REDIS_CLI} lastsave)" +%Y-%m-%d-%H.%M.%S)"
export LANG=${LANG_}

${CP_CMD} -p ${REDIS_DATA}/dump.rdb ${DUMP_FILE}
if [[ $? != 0 ]]; then
  echo "failed to copy dump file to: ${DUMP_FILE}"
  ${CMD_LOGGER} -p user.err "failed to copy dump file to: ${DUMP_FILE}"
  exit 4
fi

${FIND_CMD} ${BACKUP_DEST_DIR} -name 'dump.rdb.*' -mtime +${NUM_DAYS} -exec rm {} \;
if [[ $? -ne 0 ]]; then
  echo 'failed to delete old dump files.'
  ${LOGGER_CMD} -p user.err 'failed to delete old dump files.'
  exit 5
fi

exit 0
