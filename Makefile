default: run

build:
	@docker build \
		--tag preloaded_db:new \
		--build-arg GIT_HASH=$(shell git rev-parse HEAD) \
		.

run: build
	@docker run \
		--rm \
		--name preloaded_db \
		--publish 5432:5432 \
		--detach \
		preloaded_db:new

remove:
	@docker container rm -f preloaded_db
	@sudo lsof -i :5432 | awk 'NR!=1 {print $2}' | xargs -I {} sudo kill -9 {}

logs:
	@docker container logs preloaded_db
