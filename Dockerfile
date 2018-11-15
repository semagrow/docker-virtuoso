FROM ubuntu:18.04 as build

ENV  VIRTUOSO_COMMIT 96055f6a70a92c3098a7e786592f4d8ba8aae214

RUN  apt-get update && \
     apt-get install -y build-essential \
                        autotools-dev \
                        autoconf \
                        automake \
                        unzip \
                        wget \
                        net-tools \
                        libtool \
                        flex \
                        bison \
                        gperf \
                        gawk \
                        m4 \
                        libssl-dev \
                        libreadline-dev \
                        openssl  && \  
     apt-get install -y libssl1.0-dev && \
     wget https://github.com/openlink/virtuoso-opensource/archive/${VIRTUOSO_COMMIT}.zip  && \
     unzip ${VIRTUOSO_COMMIT}.zip && \
     rm ${VIRTUOSO_COMMIT}.zip 

WORKDIR /virtuoso-opensource-${VIRTUOSO_COMMIT}
ENV CFLAGS "-O2 -m64"

RUN  ./autogen.sh  && \
     ./configure --disable-bpel-vad \
                 --enable-conductor-vad \
                 --enable-fct-vad \
                 --disable-dbpedia-vad \
                 --disable-demo-vad \
                 --disable-isparql-vad \
                 --disable-ods-vad \
                 --disable-sparqldemo-vad \
                 --disable-syncml-vad \
                 --disable-tutorial-vad \
                 --with-readline \
                 --program-transform-name="s/isql/isql-v/"  && \
      make && \
      make install 


FROM  ubuntu:18.04

ENV  VIRTUOSO_PATH /usr/local/virtuoso-opensource
ENV  PATH  $VIRTUOSO_PATH/bin:$PATH

COPY --from=build $VIRTUOSO_PATH $VIRTUOSO_PATH
RUN  apt-get update && \
     apt-get install -y openssl libreadline-dev libssl-dev && \
     apt-get install -y libssl1.0-dev

RUN  ln -s $VIRTUOSO_PATH/var/lib/virtuoso /var/lib/virtuoso && \
     ln -s /var/lib/virtuoso/db /data

EXPOSE 8890 1111
VOLUME [ "/data" ]
WORKDIR $VIRTUOSO_PATH

COPY ./docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod 755 /docker-entrypoint.sh

ENTRYPOINT [ "/docker-entrypoint.sh" ]
CMD [ "virtuoso-t", "+wait", "+foreground" ]
