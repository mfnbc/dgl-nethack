FROM alpine:latest

# This image compiles nethack, more flexibility that way, besides I don't
# know of a distro-package that is ready for chroot

RUN apk add --no-cache gcc musl-dev linux-headers \
  autoconf automake make \
  bison flex flex-dev git groff \
  sqlite sqlite-dev \
  ncurses ncurses-dev \
  util-linux busybox-extras

WORKDIR /root

RUN git clone git://github.com/paxed/dgamelaunch.git
COPY ./dgamelaunch.conf dgamelaunch/examples/dgamelaunch.conf
COPY ./dgl_menu_main_user.txt dgamelaunch/examples/dgl_menu_main_user.txt
RUN cd dgamelaunch && \
  ./autogen.sh \
    --enable-sqlite \
    --enable-shmem \
    --with-config-file=/opt/nethack/nethack.alt.org/etc/dgamelaunch.conf && \
  make && \
  ./dgl-create-chroot

# It is possible I don't need this if I can use the UID / GID numbers
RUN cp /etc/passwd /opt/nethack/nethack.alt.org/etc

# Runs out of the box, the binary name is fixed in the dgamelaunch.conf file above
RUN git clone http://alt.org/nethack/nh343-nao.git
RUN cd nh343-nao && \
  make all && \
  make install

# The menu calls this 3.6.2, but the release number will surely change.
RUN git clone https://github.com/NetHack/NetHack.git
# AFAICT, the linux-chroot is made for this, just a few changes needed
# including removing the '-n' in post install copy command
COPY ./linux-chroot NetHack/sys/unix/hints/linux-chroot
RUN cd NetHack/ && \
  sed -i -e "/NH_DEVEL_STATUS/s/STATUS_WIP/STATUS_RELEASED/" include/global.h && \
  sys/unix/setup.sh sys/unix/hints/linux-chroot && \
  make all && \
  make install

# I might move these commands into the post-install for nethack 3.6.2
RUN chown -R games:games /opt/nethack/nethack.alt.org/nh362/
RUN mkdir /opt/nethack/nethack.alt.org/dgldir/inprogress-nh362
RUN chown games:games /opt/nethack/nethack.alt.org/dgldir/inprogress-nh362

# Simple enough w/ busybox inetd...
COPY ./inetd.conf /etc/inetd.conf

EXPOSE 23

CMD ["inetd","-f"]
