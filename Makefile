TAG = 'flo/nginx-proxy-and-streaming-media'

build: Dockerfile
	@docker build -t $(TAG) . 2>&1 | perl -ne 'BEGIN { print STDERR "Building..." } $$ctr = $$_; print STDERR "."; END { print STDERR "\n$$ctr" }'

Dockerfile: Dockerfile.m4
	m4 < $< > $@

run: Dockerfile
	docker run -d -p 80:80 -v /var/local/media:/var/local/media $(TAG)

shell: Dockerfile
	docker exec -it `docker ps -f ancestor=$(TAG) --format='{{.ID}}'` bash

.PHONY: build run shell
