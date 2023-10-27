# Parameters used to generate pv/pvc specification

INSTANCE="qserv"


# Use current namespace
NS=$(kubectl config view  --output 'jsonpath={..namespace}')
NS=$([ ! -z "$NS" ] && echo "$NS" || echo "default")

PARALLEL_SSH_CFG="$HOME/.ssh/sshqserv"
PARALLEL_SSH_MASTER="$HOME/.ssh/sshqservmaster"

REPL_CTL_HOST="sv-qserv-oct23-utility-1"
REPL_DB_HOST="sv-qserv-oct23-utility-1"
INGEST_DB_HOST="sv-qserv-oct23-utility-2"

ROOT_DATA_DIR="/qserv-data"
DATA_DIR="${ROOT_DATA_DIR}/${NS}"

MASTERS="sv-qserv-oct23-czar"
WORKERS="sv-qserv-oct23-worker-1 sv-qserv-oct23-worker-2 sv-qserv-oct23-worker-3 sv-qserv-oct23-worker-4 sv-qserv-oct23-worker-5 sv-qserv-oct23-worker-6 sv-qserv-oct23-worker-7 sv-qserv-oct23-worker-8 sv-qserv-oct23-worker-9 sv-qserv-oct23-worker-10"

SSH_CFG_OPT="-t"
