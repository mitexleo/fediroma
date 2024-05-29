#!/bin/sh

# this should all be done without needing a running instance
docker compose run --rm -e "PLEROMA_CTL_RPC_DISABLED=true" akkoma ./bin/pleroma_ctl $@
