FROM ubuntu:20.04
RUN apt-get -qq update && \
    DEBIAN_FRONTEND=noninteractive \
    apt-get install -yqq curl gawk gcc g++ git gnupg make pkg-config libssl-dev tar unzip xz-utils zlib1g-dev
RUN curl -fsS https://dlang.org/install.sh | bash -s dmd
RUN curl https://dump.cy.md/21aef3c8846946203e178c83a37beba1/kindlegen_linux_2.6_i386_v2_9.tar.gz -o- | \
    tar -C /usr/local/bin -zx kindlegen
