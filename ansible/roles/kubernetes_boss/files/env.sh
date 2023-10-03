# Parameters used to generate pv/pvc specification

INSTANCE="qserv"


# Use current namespace
NS=$(kubectl config view  --output 'jsonpath={..namespace}')
NS=$([ ! -z "$NS" ] && echo "$NS" || echo "default")

PARALLEL_SSH_CFG="$HOME/.ssh/sshqserv"
PARALLEL_SSH_MASTER="$HOME/.ssh/sshqservmaster"

REPL_CTL_HOST="sv-qserv-ssd-utility-1"
REPL_DB_HOST="sv-qserv-ssd-utility-1"
INGEST_DB_HOST="sv-qserv-ssd-utility-1"

ROOT_DATA_DIR="/qserv-data"
DATA_DIR="${ROOT_DATA_DIR}/${NS}"

MASTERS="sv-qserv-ssd-czar"
WORKERS="sv-qserv-ssd-worker-1 sv-qserv-ssd-worker-2 sv-qserv-ssd-worker-3"

SSH_CFG_OPT="-t"
