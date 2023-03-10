FROM golang:1.18-alpine as api-builder
ARG API_BIN_NAME=xp-management

ENV GO111MODULE=on \
    GOOS=linux \
    GOARCH=amd64

WORKDIR /app
COPY . .

# Build Management Service binary
WORKDIR /app/management-service
RUN go build \
    -mod=vendor \
    -o ./bin/${API_BIN_NAME}

FROM alpine:latest

# Install bash
USER root
RUN apk add --no-cache bash

ARG API_BIN_NAME=xp-management
ARG XP_UI_DIST_PATH=ui/build

ENV XPUICONFIG_SERVINGDIRECTORY "/app/xp-ui"
ENV XP_PORT "8080"
ENV XP_USER "xp"
ENV XP_USER_GROUP "app"

EXPOSE ${XP_PORT}

RUN addgroup -S ${XP_USER_GROUP} \
    && adduser -S ${XP_USER} -G ${XP_USER_GROUP} -H \
    && mkdir /app \
    && chown -R ${XP_USER}:${XP_USER_GROUP} /app

COPY --from=api-builder --chown=${XP_USER}:${XP_USER_GROUP} /app/management-service/bin/* /app/
COPY --from=api-builder --chown=${XP_USER}:${XP_USER_GROUP} /app/management-service/database /app/database/

USER ${XP_USER}
WORKDIR /app

# UI must be built outside docker
COPY --chown=${XP_USER}:${XP_USER_GROUP} ${XP_UI_DIST_PATH} ${XPUICONFIG_SERVINGDIRECTORY}/

COPY ./docker-entrypoint.sh ./

ENV XP_API_BIN "./${API_BIN_NAME}"
ENV XP_UI_DIST_DIR ${XPUICONFIG_SERVINGDIRECTORY}

ENTRYPOINT [ "./docker-entrypoint.sh" ]
