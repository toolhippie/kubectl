FROM webhippie/golang:1.18 AS build

# renovate: datasource=github-releases depName=kubernetes-sigs/kustomize
ENV KUSTOMIZE_VERSION=4.5.4

# renovate: datasource=github-releases depName=viaduct-ai/kustomize-sops
ENV KSOPS_VERSION=3.0.2

# renovate: datasource=github-releases depName=kubernetes/kubernetes
ENV KUBECTL_VERSION=1.24.0

# renovate: datasource=github-releases depName=helm/helm
ENV HELM_VERSION=3.8.2

RUN git clone -b kustomize/v${KUSTOMIZE_VERSION} https://github.com/kubernetes-sigs/kustomize.git /srv/app/src && \
  cd /srv/app/src/kustomize && \
  GO111MODULE=on go install

RUN git clone -b v${KSOPS_VERSION} https://github.com/viaduct-ai/kustomize-sops.git /srv/app/ksops && \
  cd /srv/app/ksops && \
  GO111MODULE=on go install

ARG TARGETARCH

RUN case "${TARGETARCH}" in \
		'amd64') \
			curl -sSLo- https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz | tar -xzf - --strip 1 -C /tmp; \
			curl -sSLo /tmp/kubectl https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl; \
			;; \
		'arm64') \
			curl -sSLo- https://get.helm.sh/helm-v${HELM_VERSION}-linux-arm64.tar.gz | tar -xzf - --strip 1 -C /tmp; \
			curl -sSLo /tmp/kubectl https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/arm64/kubectl; \
			;; \
		'arm') \
			curl -sSLo- https://get.helm.sh/helm-v${HELM_VERSION}-linux-arm.tar.gz | tar -xzf - --strip 1 -C /tmp; \
			curl -sSLo /tmp/kubectl https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/arm/kubectl; \
			;; \
		*) echo >&2 "error: unsupported architecture '${TARGETARCH}'"; exit 1 ;; \
	esac && \
	chmod +x /tmp/kubectl


FROM webhippie/alpine:latest
ENTRYPOINT [""]
ENV XDG_CONFIG_HOME=/usr/local/config

RUN apk update && \
  apk upgrade && \
  apk add --no-cache gnupg && \
  rm -rf /var/cache/apk/*

COPY --from=build /srv/app/bin/kustomize /usr/bin/
COPY --from=build /srv/app/bin/kustomize-sops /usr/local/config/kustomize/plugin/viaduct.ai/v1/ksops/ksops
COPY --from=build /tmp/helm /usr/bin/helm
COPY --from=build /tmp/kubectl /usr/bin/kubectl
