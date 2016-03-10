FROM ubuntu

RUN apt-get update && apt-get -y install git pkg-config dh-autoreconf liblua5.2-dev lua5.2 wget libx264-dev libtwolame-dev libasound2-dev

RUN mkdir /data/

WORKDIR /data

#The zip file by default is something stupid with spaces like Blackmagic\ DeckLink\ SDK\ 10.6.1/
#we rename it to DecklinkSDK for ease of use
#ADD Blackmagic\ DeckLink\ SDK\ 10.6.1/ /data/DecklinkSDK
ADD DecklinkSDK /data/DecklinkSDK

#Build libdvbpsi from source rather than repo cus we needed latest
WORKDIR /data
RUN git clone http://git.videolan.org/git/x264.git && cd x264 && \
    ./configure --disable-asm --enable-shared && make -j $(grep -c processor /proc/cpuinfo) && make install && cd .. 

RUN git clone https://github.com/Arcen/faac.git && cd faac && \
    ./bootstrap && ./configure && make -j $(grep -c processor /proc/cpuinfo) && make install

RUN \
    git clone https://github.com/mkrufky/libdvbpsi.git && \
    cd libdvbpsi && ./bootstrap && ./configure && make && make install && cd .. && \
    git clone https://github.com/FFmpeg/FFmpeg.git && \
    cd FFmpeg && ./configure --disable-yasm --disable-ffserver --disable-ffprobe --disable-ffplay --enable-libfaac --enable-nonfree --enable-libx264 --enable-gpl --enable-shared && make && make install


WORKDIR /data

RUN git clone https://github.com/videolan/vlc.git && \
    cd vlc && \
    ./bootstrap && \
    ./configure --disable-qt4 --disable-skins2 --disable-xcb --enable-twolame --enable-dvbpsi --disable-dbus --enable-lua --disable-mad --disable-postproc --disable-a52 --disable-libgcrypt --disable-dbus --enable-run-as-root --enable-x264 --disable-nls --enable-httpd --disable-dvdnav --disable-dshow --disable-bluray --disable-smb --disable-live555 --disable-vcd --disable-libcddb --disable-ogg --disable-mux_ogg --disable-shout --disable-mkv --disable-dvdread --disable-samplerate --disable-udev --disable-upnp --disable-mtp --disable-flac --disable-notify --disable-bonjour --disable-caca --disable-libass --disable-schroedinger --disable-theora --disable-opus --disable-speex --disable-vorbis --disable-dirac --disable-telx --disable-fluidsynth --disable-dca --disable-libmpeg2 --disable-goom --disable-dv --disable-svg --disable-kate --disable-sftp --disable-sid --disable-dc1394 --disable-opencv --disable-gnomevfs --disable-sdl --disable-taglib --disable-libxml2 --disable-portaudio --disable-telx --disable-libva --disable-jack --disable-mod --disable-projectm --disable-faad --enable-shared --with-decklink-sdk=/data/DecklinkSDK/Linux

# change version of blackmagic video here
ADD Blackmagic_Desktop_Video_Linux_10.6.1 /data/blackmagicvideo

RUN apt-get update && apt-get install -y dkms libgl1-mesa-glx libxml2 linux-headers-`uname -r` && \
    \
    cd /data/blackmagicvideo/deb/amd64 && sudo dpkg -i desktopvideo_*.deb && \
    cd ../../.. && rm -rf blackmagicvideo  && \
    \
    apt-get autoclean -y && apt-get autoremove -y && apt-get clean -y && \
    rm -rf /var/lib/apt/lists/*

RUN cd vlc && make -j $(grep -c processor /proc/cpuinfo) && make install

RUN ln -s /usr/local/lib/* /usr/lib/ || true
