build: Dockerfile
	@docker build -t flo/nginx-proxy-and-streaming-media . 2>&1 | perl -ne 'BEGIN { print STDERR "Building..." } $$ctr = $$_; print STDERR "."; END { print STDERR "\n$$ctr" }'

Dockerfile: Dockerfile.m4
	m4 < $< > $@

run: Dockerfile
	docker run -d -p 80:80 -v /var/local/media:/var/local/media flo/nginx-proxy-and-streaming-media

shell: Dockerfile
	docker run -it -p 80:80 -v /var/local/media:/var/local/media flo/nginx-proxy-and-streaming-media /bin/zsh

.PHONY: build run shell
