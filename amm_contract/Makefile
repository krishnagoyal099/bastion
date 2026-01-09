.PHONY: all build clean test

all: build

prepare:
	rustup target add wasm32-unknown-unknown

build: prepare
	cargo build --release --target wasm32-unknown-unknown
	@echo "WASM built: target/wasm32-unknown-unknown/release/storyswap_amm.wasm"
	@ls -lh target/wasm32-unknown-unknown/release/storyswap_amm.wasm

clean:
	cargo clean

test:
	cargo test
