SHELL := /bin/bash

compiler: compiler.Dockerfile
	docker build -f ${PWD}/compiler.Dockerfile -t jeylabs/poppler/compiler:latest .

build: compiler
	docker build --no-cache -f ${PWD}/builder.Dockerfile -t jeylabs/poppler:latest .

distribution: build
	docker run --rm \
		--env ZIP_FILE_NAME=poppler \
		--volume ${PWD}/export:/export \
		--volume ${PWD}/runtime:/runtime \
		--volume ${PWD}/export.sh:/export.sh:ro \
		jeylabs/poppler:latest \
		/export.sh
