#!/bin/sh
set -e

if [ -z "$1" ] ; then
  echo "usage: $0 -d"
  exit
fi

# run the same script inside a docker container, first argument is a workdir
if [ "x$1" = "x-d" ] ; then
  docker run -it --rm -v `pwd`:/src debian:bookworm-slim /src/make_dist.sh /src
  exit
fi
# now we inside a docker container, clone php-src and apply patches

cd $1

apt-get update
apt-get install -y --no-install-recommends \
    autoconf2.69 bison re2c make \
    git ca-certificates \
    wget xz-utils bzip2

export PHP_AUTOCONF=autoconf2.69
export PHP_AUTOHEADER=autoheader2.69

if [ ! -f ~/.gitconfig ] ; then
  git config --global safe.directory "*"
  git config --global core.autocrlf false
  git config --global user.email "your@email.com"
  git config --global user.name "Your Name"
fi

git clone -b PHP-7.4-CVE-2026-109618-109619 https://github.com/php/php-src.git
cd php-src
git apply ../*.patch
git commit -am "trixie compat"
git tag -a php-7.4.34 -m "7.4.34 with CVE and Debian Trixie backports"

scripts/dev/makedist php-7.4.34

echo
echo "Now COPY php-src/php-7.4.34.tar.xz -> ../7.4/trixie/fpm"
echo "Then buid docker image"

