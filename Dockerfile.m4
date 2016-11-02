define(`NGINXVERSION', `1.9.6')dnl
define(`RTMPVERSION', `1.1.7')dnl
define(`VODVERSION', `1.4')dnl
define(`SRCDIR', `/usr/src/nginx')dnl
define(`RTMPMOD', `SRCDIR/nginx-NGINXVERSION/debian/modules/nginx-rtmp-module-RTMPVERSION')dnl
define(`VODMOD', `SRCDIR/nginx-NGINXVERSION/debian/modules/nginx-vod-module-VODVERSION')dnl
define(`NGINXURL', `http://nginx.org/download/nginx-'NGINXVERSION.tar.gz)dnl
define(`RTMPURL', `https://github.com/arut/nginx-rtmp-module/archive/v'RTMPVERSION`.tar.gz')dnl
define(`NGINXPKG', NGINXVERSION`-1~jessie')
define(`NGINXDEB', `nginx_'NGINXVERSION`-1~jessie_amd64.deb')
dnl
FROM buildpack-deps:jessie

RUN echo `NGINXVERSION' NGINXVERSION

RUN apt-key adv --keyserver hkp://pgp.mit.edu:80 --recv-keys 573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62
RUN echo "deb http://nginx.org/packages/mainline/debian/ jessie nginx" >> /etc/apt/sources.list && \
    echo "deb-src http://nginx.org/packages/mainline/debian/ jessie nginx" >> /etc/apt/sources.list

RUN mkdir -p SRCDIR
WORKDIR SRCDIR

# Download nginx source
RUN apt-get update && \
    apt-get install -y ca-certificates dpkg-dev && \
    apt-get source nginx=NGINXPKG && \
    apt-get build-dep -y nginx=NGINXPKG && \
    rm -rf /var/lib/apt/lists/*

WORKDIR SRCDIR/nginx-NGINXVERSION/debian/modules/

# Download RTMP module
RUN curl -L RTMPURL | tar xz && \
    ln -s nginx-rtmp-module-RTMPVERSION nginx-rtmp-module

# Download VOD module
RUN curl -L https://github.com/kaltura/nginx-vod-module/archive/VODVERSION.tar.gz | tar xz && \
    ln -s nginx-vod-module-VODVERSION nginx-vod-module

# Add modules to build nginx debian rules
RUN sed -ri "s|--with-ipv6|--with-ipv6 --add-module=RTMPMOD --add-module=VODMOD|" \
        SRCDIR/nginx-NGINXVERSION/debian/rules

# Build nginx debian package
WORKDIR SRCDIR/nginx-NGINXVERSION
RUN dpkg-buildpackage -b

# Install nginx
WORKDIR SRCDIR
RUN dpkg -i NGINXDEB

# Add rtmp config wildcard inclusion
RUN mkdir -p /etc/nginx/rtmp.d && \
    printf "\nrtmp {\n\tinclude /etc/nginx/rtmp.d/*.conf;\n}\n" >> /etc/nginx/nginx.conf

# Install ffmpeg / aac
RUN echo 'deb http://www.deb-multimedia.org jessie main non-free' >> /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -y --force-yes deb-multimedia-keyring && \
    apt-get update && \
    apt-get install -y \
        ffmpeg

# Install Perl modules
RUN apt-get install -y cpanminus libhttp-message-perl
RUN cpanm Net::Server::HTTP

# Install zsh, dammit!
RUN apt-get install -y zsh

# Cleanup
RUN apt-get purge -yqq dpkg-dev && \
    apt-get autoremove -yqq && \
    apt-get clean -yqq && \
    rm -rf SRCDIR

# Set up NGINX config
COPY nginx/conf.d/* /etc/nginx/conf.d/
COPY nginx/rtmp.d/* /etc/nginx/rtmp.d/

# Set up httwixt config
VOLUME /var/local/media
RUN ln -sf media /var/local/httwixt
COPY conf/httwixt.conf /var/local/httwixt/httwixt.conf

# Install scripts
COPY bin/* /usr/bin/

### NO! DO NOT! # Forward request and error logs to docker log collector
### RUN ln -sf /dev/stdout /var/log/nginx/access.log
### RUN ln -sf /dev/stderr /var/log/nginx/error.log

VOLUME ["/var/cache/nginx"]

EXPOSE 80 443

CMD /usr/bin/runme

# vim:set ft=m4:
