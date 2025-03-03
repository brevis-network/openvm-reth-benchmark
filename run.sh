#!/bin/bash
set -ex

if [ -z "$BLOCK_NUMBER" ]; then
  BLOCK_NUMBER=17106222
fi
echo "BLOCK_NUMBER: $BLOCK_NUMBER"

EXTRA_ARGS=""
case "$APP" in
"fibonacci")
  echo "Prove APP: $APP"
  EXTRA_ARGS+=" --fib-n 300000"
  ;;
"tendermint" | "reth")
  echo "Prove APP: $APP"
  ;;
*)
  echo "Invalid APP: $APP"
  exit 1
  ;;
esac
if [[ "$CACHE" == "true" ]]; then
  echo "Run with cache"
else
  echo "Run with no cache"
  EXTRA_ARGS+=" --rpc-url $RPC_1"
fi
echo "EXTRA_ARGS: $EXTRA_ARGS"

cd bin/client-eth
cargo openvm build --no-transpile --features $APP
mkdir -p ../host/elf
SRC="target/riscv32im-risc0-zkvm-elf/release/openvm-client-eth"
DEST="../host/elf/openvm-client-eth"

if [ ! -f "$DEST" ] || ! cmp -s "$SRC" "$DEST"; then
  cp "$SRC" "$DEST"
fi
cd ../..

mkdir -p rpc-cache
# gupeng risc-prove
# MODE=prove-e2e # can be execute, tracegen, prove, or prove-e2e
MODE=prove # can be execute, tracegen, prove, or prove-e2e
PROFILE="maxperf"
FEATURES="bench-metrics,nightly-features,jemalloc"

arch=$(uname -m)
case $arch in
arm64 | aarch64)
  RUSTFLAGS="-Ctarget-cpu=native"
  ;;
x86_64 | amd64)
  RUSTFLAGS="-Ctarget-cpu=native -C target-feature=+avx512f"
  ;;
*)
  echo "Unsupported architecture: $arch"
  exit 1
  ;;
esac
export JEMALLOC_SYS_WITH_MALLOC_CONF="retain:true,background_thread:true,metadata_thp:always,dirty_decay_ms:-1,muzzy_decay_ms:-1,abort_conf:true"
RUSTFLAGS=$RUSTFLAGS cargo build --bin openvm-reth-benchmark --profile=$PROFILE --no-default-features --features=$FEATURES
PARAMS_DIR="params"

RUST_LOG="info,p3_=warn" OUTPUT_PATH="metrics.json" ./target/$PROFILE/openvm-reth-benchmark --kzg-params-dir $PARAMS_DIR --$MODE --block-number $BLOCK_NUMBER --chain-id 1 --cache-dir rpc-cache $EXTRA_ARGS
