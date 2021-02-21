# This is a Docker image for the Drone CI system.
# Use the following command to start the container:
#    docker run -p 127.0.0.1:80:80 -t drone/drone

FROM golang:1.14.4 as staging

env GOPATH=/gopath
env GOARCH=amd64
env GOOS=linux

COPY . /gopath/src/github.com/drone/drone/
WORKDIR /gopath/src/github.com/drone/drone

RUN go mod vendor
RUN sh scripts/build.sh

FROM alpine:3.11 as alpine
RUN apk add -U --no-cache ca-certificates

FROM alpine:3.11
EXPOSE 80 443
VOLUME /data

RUN [ ! -e /etc/nsswitch.conf ] && echo 'hosts: files dns' > /etc/nsswitch.conf

ENV GODEBUG netdns=go
ENV XDG_CACHE_HOME /data
ENV DRONE_DATABASE_DRIVER sqlite3
ENV DRONE_DATABASE_DATASOURCE /data/database.sqlite
ENV DRONE_RUNNER_OS=linux
ENV DRONE_RUNNER_ARCH=amd64
ENV DRONE_SERVER_PORT=:80
ENV DRONE_SERVER_HOST=localhost
ENV DRONE_DATADOG_ENABLED=true
ENV DRONE_DATADOG_ENDPOINT=https://stats.drone.ci/api/v1/series

COPY --from=alpine /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

COPY --from=staging /gopath/src/github.com/drone/drone/release/linux/amd64/* /bin/

ENTRYPOINT ["/bin/drone-server"]

