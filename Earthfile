VERSION 0.6
FROM alpine

ARG BASE_IMAGE
ARG IMAGE_REPOSITORY=public.ecr.aws/s0y1t3q2

ARG LUET_VERSION=0.33.0
ARG GOLINT_VERSION=1.52.2
ARG GOLANG_VERSION=1.20

ARG OS_ID=baronos
ARG OS_NAME=BARONos
ARG IMAGE_NAME=${OS_ID}/core

ARG MICROK8S_CHANNEL=latest

build-cosign:
    FROM gcr.io/projectsigstore/cosign:v1.13.1
    SAVE ARTIFACT /ko-app/cosign cosign

go-deps:
    FROM golang:$GOLANG_VERSION
    WORKDIR /build
    COPY go.mod  ./
    RUN go mod download
    RUN apt-get update && apt-get install -y upx
    SAVE ARTIFACT go.mod AS LOCAL go.mod
    SAVE ARTIFACT go.sum AS LOCAL go.sum

BUILD_GOLANG:
    COMMAND
    WORKDIR /build
    COPY . ./
    ARG BIN
    ARG SRC

    RUN go build -ldflags "-s -w" -o ${BIN} ./${SRC} && upx ${BIN}
    SAVE ARTIFACT ${BIN} ${BIN} AS LOCAL build/${BIN}

VERSION:
    COMMAND
    FROM alpine
    RUN apk add git

    COPY . ./

    RUN echo $(git describe --exact-match --tags || echo "v0.0.0-$(git log --oneline -n 1 | cut -d" " -f1)") > VERSION

    SAVE ARTIFACT VERSION VERSION

build-provider:
    FROM +go-deps
    DO +BUILD_GOLANG --BIN=agent-provider-microk8s --SRC=.

lint:
    FROM golang:$GOLANG_VERSION
    RUN wget -O- -nv https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s $GOLINT_VERSION
    WORKDIR /build
    COPY . .
    RUN golangci-lint run

base-image:
    DO +VERSION
    ARG VERSION=$(cat VERSION)

    IF [ "$BASE_IMAGE" = "" ]
        FROM DOCKERFILE -f base/Dockerfile base
        SAVE IMAGE --push $IMAGE_REPOSITORY/${IMAGE_NAME}-base:${VERSION}
    ELSE 
        FROM $BASE_IMAGE
    END

    RUN rm -rf /etc/machine-id && touch /etc/machine-id && chmod 444 /etc/machine-id

    # Enable services
    IF [ -f /sbin/openrc ]
     RUN mkdir -p /etc/runlevels/default && \
      ln -sf /etc/init.d/cos-setup-boot /etc/runlevels/default/cos-setup-boot  && \
      ln -sf /etc/init.d/cos-setup-network /etc/runlevels/default/cos-setup-network  && \
      ln -sf /etc/init.d/cos-setup-reconcile /etc/runlevels/default/cos-setup-reconcile && \
      ln -sf /etc/init.d/kairos-agent /etc/runlevels/default/kairos-agent
    # Otherwise we assume systemd
    ELSE
      RUN ls -liah /etc/systemd/system
      RUN systemctl enable cos-setup-reconcile.timer && \
          systemctl enable cos-setup-fs.service && \
          systemctl enable cos-setup-boot.service && \
          systemctl enable cos-setup-network.service
    END

    IF [ "$FLAVOR" = "debian" ]
	    RUN rm -rf /boot/initrd.img-*
    END

    IF [[ "$FLAVOR" =~ ^alpine.* ]] 
        # no dracut on those flavors, do nothing
    ELSE
        # Regenerate initrd if necessary
        RUN --no-cache kernel=$(ls /lib/modules | head -n1) && dracut -f "/boot/initrd-${kernel}" "${kernel}" && ln -sf "initrd-${kernel}" /boot/initrd
        RUN --no-cache kernel=$(ls /lib/modules | head -n1) && depmod -a "${kernel}"
    END

    IF [ "$FLAVOR" = "fedora" ] || [ "$FLAVOR" = "rockylinux" ]
        # https://github.com/kairos-io/elemental-cli/blob/23ca64435fedb9f521c95e798d2c98d2714c53bd/pkg/elemental/elemental.go#L553
        RUN rm -rf /boot/initramfs-*
    END

    # Set /boot/vmlinuz pointing to our kernel so elemental-cli can use it
    # https://github.com/kairos-io/elemental-cli/blob/23ca64435fedb9f521c95e798d2c98d2714c53bd/pkg/elemental/elemental.go#L553
    IF [ ! -e "/boot/vmlinuz" ]
        # If it's an ARM flavor, we want a symlink here from zImage/Image
        # Check that its not a symlink already or grub will fail!
        IF [ -e "/boot/Image" ] && [ ! -L "/boot/Image" ]
            RUN ln -sf Image /boot/vmlinuz
        ELSE IF [ -e "/boot/zImage" ]
            IF  [ ! -L "/boot/zImage" ]
                RUN ln -sf zImage /boot/vmlinuz
            ELSE
                RUN kernel=$(ls /boot/zImage-* | head -n1) && if [ -e "$kernel" ]; then ln -sf "${kernel#/boot/}" /boot/vmlinuz; fi
            END
        ELSE
            # Debian has vmlinuz-VERSION
            RUN kernel=$(ls /boot/vmlinuz-* | head -n1) && if [ -e "$kernel" ]; then ln -sf "${kernel#/boot/}" /boot/vmlinuz; fi
            RUN kernel=$(ls /boot/Image-* | head -n1) && if [ -e "$kernel" ]; then ln -sf "${kernel#/boot/}" /boot/vmlinuz; fi
        END
    END

    RUN rm -rf /tmp/*

image:
    DO +VERSION
    ARG VERSION=$(cat VERSION)

    FROM +base-image

    ENV DEBIAN_FRONTEND=noninteractive

    RUN apt-get update && apt-get upgrade -y && apt-get install -y \
            nohang \
            iptables-persistent \
        && apt-get clean && rm -rf /var/lib/apt/lists/* && rm -rf /var/cache/*

    RUN snap download microk8s --channel=$MICROK8S_CHANNEL --target-directory /opt/microk8s/snaps --basename microk8s
    RUN snap download core  --target-directory /opt/microk8s/snaps --basename core

    COPY +build-provider/agent-provider-microk8s /system/providers/agent-provider-microk8s
    COPY scripts/cloudinit /opt/microk8s/scripts
    RUN chmod +x /opt/microk8s/scripts/*

    COPY overlay /tmp/overlay
    RUN find /tmp/overlay -type f | xargs perl -pi -e "s/{{ BUILD_OS_VERSION }}/${VERSION}/" && rsync -rt /tmp/overlay/ / && rm -rf /tmp/overlay


    RUN luet install -y utils/edgevpn utils/k9s utils/nerdctl container/kubectl utils/kube-vip && luet cleanup

    RUN mkdir -p /opt/baronos/bin && curl -s https://fluxcd.io/install.sh | sudo -E bash /dev/stdin /opt/baronos/bin/flux

    RUN rm -rf /var/cache/* || journalctl --vacuum-size=1K || rm /etc/machine-id || rm /var/lib/dbus/machine-id || rm /etc/hostname || touch /etc/machine-id && ln -s /etc/machine-id /var/lib/dbus/machine-id || chmod 444 /etc/machine-id

    SAVE IMAGE --push $IMAGE_REPOSITORY/${IMAGE_NAME}:v${MICROK8S_CHANNEL}
    SAVE IMAGE --push $IMAGE_REPOSITORY/${IMAGE_NAME}:${VERSION}_v${MICROK8S_CHANNEL}

cosign:
    ARG --required ACTIONS_ID_TOKEN_REQUEST_TOKEN
    ARG --required ACTIONS_ID_TOKEN_REQUEST_URL

    ARG --required REGISTRY
    ARG --required REGISTRY_USER
    ARG --required REGISTRY_PASSWORD

    DO +VERSION
    ARG VERSION=$(cat VERSION)

    FROM image

    ENV ACTIONS_ID_TOKEN_REQUEST_TOKEN=${ACTIONS_ID_TOKEN_REQUEST_TOKEN}
    ENV ACTIONS_ID_TOKEN_REQUEST_URL=${ACTIONS_ID_TOKEN_REQUEST_URL}

    ENV REGISTRY=${REGISTRY}
    ENV REGISTRY_USER=${REGISTRY_USER}
    ENV REGISTRY_PASSWORD=${REGISTRY_PASSWORD}

    ENV COSIGN_EXPERIMENTAL=1
    COPY +build-cosign/cosign /usr/local/bin/

    RUN echo $REGISTRY_PASSWORD | docker login -u $REGISTRY_USER --password-stdin $REGISTRY

    RUN cosign sign $IMAGE_REPOSITORY/${IMAGE_NAME}:v${MICROK8S_CHANNEL}
    RUN cosign sign $IMAGE_REPOSITORY/${IMAGE_NAME}:${VERSION}_v${MICROK8S_CHANNEL}
