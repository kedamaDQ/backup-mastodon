#
# backup mastodon
#
MKDIR_CMD='/bin/mkdir'
LOGGER_CMD='/usr/bin/logger'
CP_CMD='/bin/cp'
FIND_CMD='/usr/bin/find'

SCRIPT_DIR="$(cd $(dirname $0); pwd)"
SUB_SCRIPT_DIR="${SCRIPT_DIR}/backup-mastodon.d"

# load .env file
ENV_FILE="${SCRIPT_DIR}/.env.backup-mastodon"
if [[ ! -f "${ENV_FILE}" ]]; then
  echo "file not found: ${ENV_FILE}"
  ${LOGGER_CMD} -p user.err "file not found: ${ENV_FILE}"
  exit 1
fi
source ${SCRIPT_DIR}/.env.backup-mastodon

# create destination directory if not exist
${MKDIR_CMD} -p ${BACKUP_DEST_DIR}
if [[ $? -ne 0 ]]; then
  echo "failed to create backup destination directory: ${BACKUP_DEST_DIR}"
  ${LOGGER_CMD} -p user.err "failed to create backup destination directory: ${BACKUP_DEST_DIR}"
  exit 2
fi

echo 'start to backup mastodon.'

# backup mastodon .env.production
echo 'backing up .env.production...'
ENV_PROD="env.production.$(date +%Y-%m-%d-%H.%M.%S)"
${CP_CMD} -p ${MASTODON_DIR}/.env.production ${BACKUP_DEST_DIR}/${ENV_PROD}
if [[ $? -ne 0 ]]; then
  echo 'failed to backup .env.production.'
  ${LOGGER_CMD} -p user.err 'failed to backup .env.production.'
  exit 3
fi

# delete old .env.production
${FIND_CMD} ${BACKUP_DEST_DIR} -name "env.production.*" -mtime +${NUM_DAYS} -exec rm {} \;
if [[ $? -ne 0 ]]; then
  echo 'failed to delete old .env.production'
  ${LOGGER_CMD} -p user.err 'failed to delete old .env.production'
  exit 4
fi

# backup redis database
echo 'backing up redis database...'
${SUB_SCRIPT_DIR}/backup-redis.sh ${BACKUP_DEST_DIR}
if [[ $? -ne 0 ]]; then
  echo 'failed to backup redis database.'
  ${LOGGER_CMD} -p user.err 'failed to backup redis database.'
  exit 5
fi

# backup postgresql database
echo 'backing up postgresql database...'
${SUB_SCRIPT_DIR}/backup-postgresql.sh ${BACKUP_DEST_DIR}
if [[ $? -ne 0 ]]; then
  echo 'failed to backup postgresql database.'
  ${LOGGER_CMD} -p user.err 'failed to backup postgresql database.'
  exit 6
fi

echo 'finished to backup mastodon.'
exit 0
