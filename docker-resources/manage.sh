#!/bin/sh

podman compose run -e "PLEROMA_CTL_RPC_DISABLED=true" --rm akkoma ./bin/pleroma_ctl $@
