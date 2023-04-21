ARG BASE_IMAGE=ubuntu:22.04

FROM $BASE_IMAGE

ENV DEBIAN_FRONTEND=noninteractive

COPY modules.keep firmware.keep /tmp/

RUN  sed -i -e 's/http:\/\/archive\.ubuntu\.com\/ubuntu\//http:\/\/mirror\.math\.princeton\.edu\/pub\/ubuntu\//' /etc/apt/sources.list \
  && sed -i -e 's/http:\/\/security\.ubuntu\.com\/ubuntu\//http:\/\/mirror\.math\.princeton\.edu\/pub\/ubuntu\//' /etc/apt/sources.list \
  && apt-get update \
  && apt-get install -y --no-install-recommends \
    gnupg \
    software-properties-common \
  && add-apt-repository ppa:oibaf/test \
  && apt-get update \
  && apt-get install -y --no-install-recommends \
    conntrack \
    console-data \
    coreutils \
    cryptsetup \
    curl \
    debianutils \
    dmsetup \
    dosfstools \
    dracut \
    dracut-live \
    dracut-network \
    e2fsprogs \
    efibootmgr \
    firmware-sof-signed \
    fuse3 \
    gawk \
    gdisk \
    grub-efi-amd64-bin \
    grub-efi-amd64-signed \
    grub-pc-bin \
    grub2 \
    grub2-common \
    haveged \
    iproute2 \
    iptables \
    isc-dhcp-common \
    jq \
    kbd \
    lldpd \
    lvm2 \
    mdadm \
    nbd-client \
    ncurses-term \
    networkd-dispatcher \
    nfs-common \
    open-iscsi \
    open-vm-tools \
    openssh-server \
    os-prober \
    packagekit-tools \
    parted \
    pigz \
    polkitd \
    publicsuffix \
    rsync \
    shared-mime-info \
    snapd \
    snmpd \
    squashfs-tools \
    sudo \
    systemd \
    systemd-hwe-hwdb \
    systemd-timesyncd \
    thermald \
    ubuntu-advantage-tools \
    unattended-upgrades \
    xdg-user-dirs \
    xxd \
    xz-utils \
    zerofree \
    console-data \
    zfsutils-linux \
    git \
    vim \
    less \
    linux-image-generic \
    nvidia-utils-525-server \
    linux-modules-nvidia-525-server-generic \
 && for DIR in firmware; do \
        mkdir /usr/lib/$DIR.keep; \
        rsync -rat --ignore-missing-args --include-from=/tmp/$DIR.keep --exclude='*' /usr/lib/$DIR/ /usr/lib/$DIR.keep; \
        rm -rf /usr/lib/$DIR && mv /usr/lib/$DIR.keep /usr/lib/$DIR; \
    done \
 && apt-get clean && rm -rf /var/lib/apt/lists/* && rm -rf /var/cache/*

COPY --from=quay.io/kairos/framework:v2.0.0_ubuntu-22-lts / /

RUN ln -s /usr/sbin/grub-install /usr/sbin/grub2-install \
  && ln -s /usr/bin/grub-editenv /usr/bin/grub2-editenv \ 
  && systemctl enable systemd-networkd \
  && systemctl enable ssh \
  && cp -v /usr/share/systemd/tmp.mount /etc/systemd/system/ \
  && systemctl enable tmp.mount \
  && chown root:root /usr/bin/sudo && chmod 4755 /usr/bin/sudo \
  && rm -rf /etc/ssh/ssh_host_* \
  && rm /etc/update-motd.d/10-help-text /etc/update-motd.d/50-motd-news /etc/update-motd.d/60-unminimize /etc/legal && ln -s /usr/share/base-files/motd /etc/legal
