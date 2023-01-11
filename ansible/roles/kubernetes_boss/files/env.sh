# Parameters used to generate pv/pvc specification

INSTANCE="qserv"

# Use current namespace
NS=$(kubectl config view  --output 'jsonpath={..namespace}')
NS=$([ ! -z "$NS" ] && echo "$NS" || echo "default")

PARALLEL_SSH_CFG="$HOME/.ssh/sshqserv"
PARALLEL_SSH_MASTER="$HOME/.ssh/sshqservmaster"

REPL_DB_HOST="qserv-czar-pool"
INGEST_DB_HOST="qserv-czar-pool"

ROOT_DATA_DIR="/qserv-data"
DATA_DIR="${ROOT_DATA_DIR}/${NS}"

MASTERS="qserv-czar-pool"
WORKERS="qserv-utility-pool qserv-worker-pool"

SSH_CFG_OPT="-t"
