# Build pinned upstream sources: public MinIO/mc images are no longer available.
FROM golang:1.24.7-bookworm AS server-build
WORKDIR /src
RUN git init && git remote add origin https://github.com/minio/minio.git \
    && git fetch --depth=1 origin 01ce918d8279a20e4706b96a64396146894adee4 \
    && git checkout --detach FETCH_HEAD \
    && CGO_ENABLED=0 go build -trimpath -o /out/minio .

FROM golang:1.24.7-bookworm AS client-build
WORKDIR /src
RUN git init && git remote add origin https://github.com/minio/mc.git \
    && git fetch --depth=1 origin d6541ea280b73a834b64d4097e21f2be77676104 \
    && git checkout --detach FETCH_HEAD \
    && CGO_ENABLED=0 go build -trimpath -o /out/mc .

FROM debian:bookworm-slim AS runtime
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl \
    && rm -rf /var/lib/apt/lists/*

FROM runtime AS server
COPY --from=server-build /out/minio /usr/local/bin/minio
COPY --from=server-build /src/LICENSE /usr/share/licenses/minio/LICENSE
ENTRYPOINT ["minio"]

FROM runtime AS client
COPY --from=client-build /out/mc /usr/local/bin/mc
COPY --from=client-build /src/LICENSE /usr/share/licenses/mc/LICENSE
ENTRYPOINT ["mc"]
