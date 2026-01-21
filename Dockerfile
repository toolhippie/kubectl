FROM ghcr.io/dockhippie/golang:1.25@sha256:bf991953dcf526ba5abf70bb6f5218ebccfe7b1eac3b20c44c4b92a190201852 AS build

# renovate: datasource=github-releases depName=kubernetes-sigs/kustomize
ENV KUSTOMIZE_VERSION=5.8.0

# renovate: datasource=github-releases depName=viaduct-ai/kustomize-sops
ENV KSOPS_VERSION=4.4.0

# renovate: datasource=github-releases depName=kubernetes/kubernetes
ENV KUBECTL_VERSION=1.35.0

# renovate: datasource=github-releases depName=helm/helm
ENV HELM_VERSION=4.0.5

# renovate: datasource=github-releases depName=fluxcd/flux2
ENV FLUXCD_VERSION=2.7.5

# renovate: datasource=github-releases depName=vmware-tanzu/velero
ENV VELERO_VERSION=1.17.2

RUN git clone -b kustomize/v${KUSTOMIZE_VERSION} https://github.com/kubernetes-sigs/kustomize.git /srv/app/src && \
  cd /srv/app/src/kustomize && \
  GO111MODULE=on go install

RUN git clone -b v${KSOPS_VERSION} https://github.com/viaduct-ai/kustomize-sops.git /srv/app/ksops && \
  cd /srv/app/ksops && \
  GO111MODULE=on go install

ARG TARGETARCH

RUN case "${TARGETARCH}" in \
		'amd64') \
			curl -sSLo /tmp/kubectl https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl; \
			curl -sSLo- https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz | tar -xzf - --strip 1 -C /tmp; \
			curl -sSLo- https://github.com/fluxcd/flux2/releases/download/v${FLUXCD_VERSION}/flux_${FLUXCD_VERSION}_linux_amd64.tar.gz | tar -xzf - -C /tmp; \
			curl -sSLo- https://github.com/vmware-tanzu/velero/releases/download/v${VELERO_VERSION}/velero-v${VELERO_VERSION}-linux-amd64.tar.gz | tar -xzf - --strip 1 -C /tmp; \
			;; \
		'arm64') \
			curl -sSLo /tmp/kubectl https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/arm64/kubectl; \
			curl -sSLo- https://get.helm.sh/helm-v${HELM_VERSION}-linux-arm64.tar.gz | tar -xzf - --strip 1 -C /tmp; \
			curl -sSLo- https://github.com/fluxcd/flux2/releases/download/v${FLUXCD_VERSION}/flux_${FLUXCD_VERSION}_linux_arm64.tar.gz | tar -xzf - -C /tmp; \
			curl -sSLo- https://github.com/vmware-tanzu/velero/releases/download/v${VELERO_VERSION}/velero-v${VELERO_VERSION}-linux-arm64.tar.gz | tar -xzf - --strip 1 -C /tmp; \
			;; \
		'arm') \
			curl -sSLo /tmp/kubectl https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/arm/kubectl; \
			curl -sSLo- https://get.helm.sh/helm-v${HELM_VERSION}-linux-arm.tar.gz | tar -xzf - --strip 1 -C /tmp; \
			curl -sSLo- https://github.com/fluxcd/flux2/releases/download/v${FLUXCD_VERSION}/flux_${FLUXCD_VERSION}_linux_arm.tar.gz | tar -xzf - -C /tmp; \
			curl -sSLo- https://github.com/vmware-tanzu/velero/releases/download/v${VELERO_VERSION}/velero-v${VELERO_VERSION}-linux-arm.tar.gz | tar -xzf - --strip 1 -C /tmp; \
			;; \
		*) echo >&2 "error: unsupported architecture '${TARGETARCH}'"; exit 1 ;; \
	esac && \
	chmod +x /tmp/kubectl

FROM ghcr.io/dockhippie/alpine:3.23@sha256:dd0a8a957cb409bde4a96e04af7b59b16f3436817784c67afb9b6bc431672e3e
ENTRYPOINT [""]
ENV XDG_CONFIG_HOME=/usr/local/config

RUN apk update && \
  apk upgrade && \
  apk add --no-cache gnupg && \
  rm -rf /var/cache/apk/*

COPY --from=build /srv/app/bin/kustomize /usr/bin/
COPY --from=build /srv/app/bin/kustomize-sops /usr/local/config/kustomize/plugin/viaduct.ai/v1/ksops/ksops
COPY --from=build /srv/app/bin/kustomize-sops /usr/bin/ksops
COPY --from=build /tmp/kubectl /usr/bin/kubectl
COPY --from=build /tmp/helm /usr/bin/helm
COPY --from=build /tmp/flux /usr/bin/flux
COPY --from=build /tmp/velero /usr/bin/velero
