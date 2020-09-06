FROM debian:buster
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    poppler-utils \
    imagemagick \
    make
WORKDIR /neolithic-axes
