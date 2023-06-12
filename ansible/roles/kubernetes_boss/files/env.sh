# Parameters used to generate pv/pvc specification

INSTANCE="qserv"


# Use current namespace
NS=$(kubectl config view  --output 'jsonpath={..namespace}')
NS=$([ ! -z "$NS" ] && echo "$NS" || echo "default")

PARALLEL_SSH_CFG="$HOME/.ssh/sshqserv"
PARALLEL_SSH_MASTER="$HOME/.ssh/sshqservmaster"

REPL_CTL_HOST="sv-qserv-utility-1"
REPL_DB_HOST="sv-qserv-utility-1"
INGEST_DB_HOST="sv-qserv-utility-2"

ROOT_DATA_DIR="/qserv-data"
DATA_DIR="${ROOT_DATA_DIR}/${NS}"

MASTERS="sv-qserv-czar"
WORKERS="sv-qserv-worker-1 sv-qserv-worker-2 sv-qserv-worker-3 sv-qserv-worker-4 sv-qserv-worker-5"

SSH_CFG_OPT="-t"
