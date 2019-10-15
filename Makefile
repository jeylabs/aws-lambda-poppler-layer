SHELL := /bin/bash

build:
	docker build --no-cache -t jeylabs/poppler:latest .

distribution: build
	docker run --rm \
		--env ZIP_FILE_NAME=poppler \
		--volume ${PWD}/export:/export \
		--volume ${PWD}/export.sh:/export.sh:ro \
		jeylabs/poppler:latest \
		/export.sh
