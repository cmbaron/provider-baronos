ARG BASE_IMAGE=$BASE

FROM $BASE_IMAGE
ARG VERSION
ARG MICROK8S_CHANNEL=1.27

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y \
        nohang \
        iptables-persistent \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* && rm -rf /var/cache/*

COPY --from=quay.io/kairos/framework:v2.0.0_ubuntu-22-lts / /

RUN mkdir -p /opt/microk8s/snap \
 && snap download microk8s --channel=$MICROK8S_CHANNEL --target-directory /opt/microk8s/snaps --basename microk8s \
 && snap download core  --target-directory /opt/microk8s/snaps --basename core

# Activate Kairos services
RUN systemctl enable cos-setup-reconcile.timer && \
          systemctl enable cos-setup-fs.service && \
          systemctl enable cos-setup-boot.service && \
          systemctl enable cos-setup-network.service

RUN kernel=$(ls /lib/modules | head -n1) && \
    dracut -f "/boot/initrd-${kernel}" "${kernel}" && \
    ln -sf "initrd-${kernel}" /boot/initrd && \
    depmod -a "${kernel}"

COPY overlay /tmp/overlay
RUN find /tmp/overlay -type f | xargs perl -pi -e "s/{{ BUILD_OS_VERSION }}/${VERSION}/" && rsync -rt /tmp/overlay/ / && rm -rf /tmp/overlay

RUN rm /etc/update-motd.d/10-help-text /etc/update-motd.d/50-motd-news /etc/update-motd.d/60-unminimize /etc/legal && ln -s /usr/share/base-files/motd /etc/legal

# install luet packages from provider-kairos/Earthfile:+docker
RUN luet install -y utils/edgevpn utils/k9s utils/nerdctl container/kubectl utils/kube-vip && luet cleanup

RUN mkdir -p /opt/baronos/bin && curl -s https://fluxcd.io/install.sh | sudo -E bash /dev/stdin /opt/baronos/bin/flux

RUN rm -rf /var/cache/* || journalctl --vacuum-size=1K || rm /etc/machine-id || rm /var/lib/dbus/machine-id || rm /etc/hostname || touch /etc/machine-id && ln -s /etc/machine-id /var/lib/dbus/machine-id || chmod 444 /etc/machine-id

