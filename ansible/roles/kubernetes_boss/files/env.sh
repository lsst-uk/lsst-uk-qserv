# Parameters used to generate pv/pvc specification

INSTANCE="qserv"


# Use current namespace
NS=$(kubectl config view  --output 'jsonpath={..namespace}')
NS=$([ ! -z "$NS" ] && echo "$NS" || echo "default")

PARALLEL_SSH_CFG="$HOME/.ssh/sshqserv"
PARALLEL_SSH_MASTER="$HOME/.ssh/sshqservmaster"

REPL_DB_HOST="gb-qserv2-utility-1"
INGEST_DB_HOST="gb-qserv2-utility-1"

ROOT_DATA_DIR="/qserv-data"
DATA_DIR="${ROOT_DATA_DIR}/${NS}"

MASTERS="gb-qserv2-czar"
WORKERS="gb-qserv2-worker-1 gb-qserv2-worker-2 gb-qserv2-worker-3"

SSH_CFG_OPT="-t"
