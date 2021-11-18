build:
	cargo build --release

image-attestation-server:
	docker build -t attestation-server -f attester/Dockerfile attester/ 
