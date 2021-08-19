FROM webhippie/golang:1.16 AS build

ENV KUSTOMIZE_VERSION=kustomize/v4.2.0

RUN git clone -b ${KUSTOMIZE_VERSION} https://github.com/kubernetes-sigs/kustomize.git /srv/app/src && \
  cd /srv/app/src/kustomize && \
  GO111MODULE=on go install

FROM webhippie/alpine:latest
ENTRYPOINT [""]

# renovate: datasource=github-releases depName=kubernetes/kubernetes
ENV KUBECTL_VERSION=1.22.1

ARG TARGETARCH=amd64

RUN apk update && \
  apk upgrade && \
  case "${TARGETARCH}" in \
		'amd64') \
			wget -qO /usr/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl; \
			;; \
		'arm64') \
			wget -qO /usr/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/arm64/kubectl; \
			;; \
		'arm') \
			wget -qO /usr/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/arm/kubectl; \
			;; \
		*) echo >&2 "error: unsupported architecture '${TARGETARCH}'"; exit 1 ;; \
	esac && \
  chmod +x /usr/bin/kubectl && \
  rm -rf /var/cache/apk/*

COPY --from=build /srv/app/bin/kustomize /usr/bin/
