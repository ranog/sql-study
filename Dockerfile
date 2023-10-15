# dump build stage
FROM postgres:11-alpine as dumper

COPY init.sql /docker-entrypoint-initdb.d/

RUN ["sed", "-i", "s/exec \"$@\"/echo \"skipping...\"/", "/usr/local/bin/docker-entrypoint.sh"]

ENV PG_USER=postgres
ENV PGDATA=/data
ENV POSTGRES_HOST_AUTH_METHOD=trust

RUN ["/usr/local/bin/docker-entrypoint.sh", "postgres"]

# final build stage
FROM postgres:11-alpine

COPY --from=dumper /data $PGDATA
