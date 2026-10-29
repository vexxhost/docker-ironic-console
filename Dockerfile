# SPDX-FileCopyrightText: © 2026 VEXXHOST, Inc.
# SPDX-License-Identifier: GPL-3.0-or-later

# Console container started by ironic-conductor for each bare metal graphical
# console. Built from upstream Ironic's tools/vnc-container.
FROM scratch AS src
ADD https://github.com/openstack/ironic.git#d689812fb50bdefe12db17d5ca67be6a6bd59155 /

FROM ubuntu:24.04@sha256:68ee22004a9109b44973313b02ff7b1de250f1de0f5ecb628d73f579aaff33ac
ENV FIREFOX_USER=firefox
ENV FIREFOX_USER_HOME=/home/${FIREFOX_USER}
RUN <<SCRIPT bash -xe
apt-get update -qq
apt-get install -qq -y --no-install-recommends \
    curl dumb-init iproute2 procps psmisc python3-requests \
    software-properties-common x11vnc xvfb
add-apt-repository -y ppa:mozillateam/ppa
apt-get install -qq -y --no-install-recommends firefox-esr
apt-get purge -qq -y software-properties-common
apt-get autoremove -qq -y
apt-get clean
rm -rf /var/lib/apt/lists/*
groupadd -g 42424 ${FIREFOX_USER}
useradd -u 42424 -g 42424 --create-home --home-dir ${FIREFOX_USER_HOME} --shell /bin/bash ${FIREFOX_USER}
SCRIPT
ENV DISPLAY_WIDTH=1280 \
    DISPLAY_HEIGHT=960 \
    APP=fake \
    APP_INFO={} \
    READ_ONLY=False \
    DEBUG=0 \
    FIREFOX=firefox-esr \
    FIREFOX_PROFILE_DIR=/home/firefox/.ironic-vnc-profile \
    EXTENSION_PATH=/usr/lib/firefox-esr-addons/extensions/@ironic-console.openstack.org
COPY --from=src /tools/vnc-container/bin/ /usr/local/bin/
COPY --from=src /tools/vnc-container/drivers /drivers
COPY --from=src --chown=42424:42424 /tools/vnc-container/extension /usr/lib/firefox-esr-addons/extensions/@ironic-console.openstack.org
# The entrypoint writes the Firefox policies and the extension config at start,
# so the unprivileged user owns those two locations.
RUN install -d -o 42424 -g 42424 /etc/firefox/policies
COPY runuser /usr/local/sbin/runuser
USER 42424:42424
EXPOSE 5900
ENTRYPOINT ["/usr/bin/dumb-init", "--single-child", "--"]
CMD ["/usr/local/bin/start-x11vnc.py"]
