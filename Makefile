SHELL := /bin/bash

build:
	docker build -t talis/poppler:latest .

distribution: build
	docker run --rm \
		--env ZIP_FILE_NAME=poppler \
		--volume ${PWD}/export:/export \
		--volume ${PWD}/runtime:/runtime \
		--volume ${PWD}/export.sh:/export.sh:ro \
		talis/poppler:latest \
		/export.sh
