TAG = 'flo/nginx-proxy-and-streaming-media'

build: Dockerfile
	@docker build -t $(TAG) . 2>&1 | perl -ne 'BEGIN { print STDERR "Building..." } $$ctr = $$_; print STDERR "."; END { print STDERR "\n$$ctr" }'

Dockerfile: Dockerfile.m4
	m4 < $< > $@

start: run

run: Dockerfile
	docker run -d -p 80:80 --net=host -v /var/local/media:/var/local/media $(TAG)

stop: 
	docker stop `docker ps -f ancestor=$(TAG) --format='{{.ID}}'`

shell: Dockerfile
	docker exec -it `docker ps -f ancestor=$(TAG) --format='{{.ID}}'` zsh

.PHONY: build start run stop shell
