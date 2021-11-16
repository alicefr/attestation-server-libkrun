build:
	cargo build --release

image:
	docker build -t attestation-server .
