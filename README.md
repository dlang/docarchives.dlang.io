dlang.org archives
------------------

All links to compiled archives are listed in [ARCHIVES.md](ARCHIVES.md).

Older versions aren't currently supported.

Future work
-----------

For each release, a `docs.json` with all symbols has been saved.
With these files a aggregated, searchable overview bar with a symbols
or arguments first introduction and deprecation could be generated.

Current limitations
-------------------

- doesn't contain the `/library` files from DDox.

Prerequesites
-------------

Building documentation assumes the following is set-up:

 - An ubuntu 20.04 LTS container or chroot.
 - Build dependencies installed `curl gawk gcc g++ git gnupg make pkg-config libssl-dev tar unzip xz-utils zlib1g-dev`
 - A DMD compiler [installed and activated](https://dlang.org/download.html).
 - [Kindlegen](https://dump.cy.md/21aef3c8846946203e178c83a37beba1/kindlegen_linux_2.6_i386_v2_9.tar.gz) extracted and installed.

The provided [Dockerfile](contrib/Dockerfile) can be used as build environment in the following way:
```bash
# docker build -t docarchives.dlang.io contrib
# docker run -v $PWD:/build -it docarchives.dlang.io \
    bash -c 'source /root/dlang/*/activate; cd /build; ./builder.d v2.098.0'
```
