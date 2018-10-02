FROM panard/wine:custom
MAINTAINER Panard <panard@backzone.net>
CMD mtgo

ENV WINE_USER wine
ENV WINE_UID 1000
ENV WINEPREFIX /home/wine/.wine
RUN useradd -u $WINE_UID -d /home/wine -m -s /bin/bash $WINE_USER
WORKDIR /home/wine

# Winetricks
ARG WINETRICKS_VERSION=20180815
ADD https://raw.githubusercontent.com/Winetricks/winetricks/$WINETRICKS_VERSION/src/winetricks /usr/local/bin/winetricks
RUN chmod 755 /usr/local/bin/winetricks

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        cabextract \
        xauth \
        xvfb \
    && su - $WINE_USER -c 'wineboot -i' \
    && su - $WINE_USER -c 'xvfb-run -a taskset -c 0 winetricks -q corefonts dotnet462 win7' \
    && su - $WINE_USER -c 'winetricks sound=disabled'\
    && su - $WINE_USER -c 'wineboot -s' \
    && rm -rf /home/wine/.cache \
    && apt remove -y --purge xauth xvfb \
    && apt autoremove -y --purge \
    && apt clean -y && rm -rf /var/lib/apt/lists/*

###
# Sound support
###
RUN apt update && apt install -y --no-install-recommends \
        gstreamer1.0-plugins-good \
        gstreamer1.0-tools \
        gstreamer1.0-pulseaudio \
        pulseaudio-utils \
    && apt autoremove -y --purge \
    && apt clean -y && rm -rf /var/lib/apt/lists/* \
    && for x in alpha avi cutter gio; do \
        rm /usr/lib/i386-linux-gnu/gstreamer-1.0/libgst$x.so; done
COPY extra/pulse-client.conf /etc/pulse/client.conf

ENV WINEDEBUG -all,err+all

COPY extra/mtgo.sh /usr/local/bin/mtgo

ADD --chown=wine:wine http://mtgoclientdepot.onlinegaming.wizards.com/setup.exe /opt/mtgo/mtgo.exe

USER wine

RUN gst-inspect-1.0

# hack to allow mounting of user.reg and system.reg from host
# see https://github.com/pauleve/docker-mtgo/issues/6
RUN cd .wine && mkdir host \
    && mv user.reg system.reg host/ \
    && ln -s host/*.reg .

COPY extra/host-webbrowser /usr/local/bin/xdg-open
