FROM buildpack-deps:jammy AS builder

ENV POSTGRES_VERSION 15.4

# Download source
RUN set -eu; \
	mkdir -p /tmp/source/build_dir; \
	cd /tmp/source; \
	wget -O postgresql.tar.bz2 https://ftp.postgresql.org/pub/source/v${POSTGRES_VERSION}/postgresql-${POSTGRES_VERSION}.tar.bz2; \
	tar -xf postgresql.tar.bz2 --strip-components=1; \
	rm postgresql.tar.bz2

# Install Postgres dependencies
RUN set -e; \
	apt-get update && apt-get upgrade -y; \
	apt-get install -y --no-install-recommends \
		clang \
		llvm-dev \
		bison \
		flex \
		python3-dev \
		libldap-dev \
		tcl-dev \
		libperl-dev \
		liblz4-dev; \
	rm -rf /var/lib/apt/lists/*;

# Configure source
WORKDIR /tmp/source/build_dir
RUN set -e; \
	gnuArch=$(dpkg-architecture --query DEB_BUILD_GNU_TYPE); \
	../configure --prefix=/pgsql --build="$gnuArch" CFLAGS='-O3 -pipe' \
		--with-perl \
		--with-python \
		--with-tcl \
		--with-llvm \
		--with-lz4 \
		--with-zstd \
		--with-ssl=openssl \
		--with-gssapi \
		--with-ldap \
		--with-uuid=e2fs \
		--with-libxml \
		--with-libxslt

# Compile
RUN set -e; \
	make -j $((`nproc`+2))  world-bin; \
	make install-world-bin; \
	rm -rf /tmp/source/

# Prepare system
RUN set -e; \
	apt-get update && apt-get install -y --no-install-recommends \
		rsync \
		locales \
		tree \
		htop \
		python3-pip; \
	rm -rf /var/lib/apt/lists/*; \
	pip install git+https://github.com/larsks/dockerize

RUN set -e; \
	groupadd postgres -r --gid=1000; \
	useradd  postgres -r --gid=1000 --uid=1000 --home-dir=/var/pgsql --shell=/sbin/nologin; \
	dockerize --filetools --group postgres --user postgres --no-build --output-dir /tmp/dockerize \
		/bin/bash \
		/usr/bin/localedef \
		/usr/bin/locale \
		/usr/bin/sleep \
		/usr/bin/clear \
		/usr/bin/gzip \
		/usr/bin/tree \
		/usr/bin/htop \
		/pgsql/bin/*

RUN set -e; \
	rsync -a --ignore-existing /pgsql /tmp/dockerize/; \
	rsync -a /usr/lib/locale          /tmp/dockerize/usr/lib/; \
	rsync -a /usr/share/i18n          /tmp/dockerize/usr/share/; \
	rsync -a /lib/terminfo            /tmp/dockerize/lib/; \
	ln -s bash /tmp/dockerize/bin/sh; \
	rm /tmp/dockerize/Dockerfile; \
	rm -rf /tmp/source

# For vulnerability scanners
RUN set -e; \
	mkdir -p /tmp/dockerize/var/lib/dpkg; \
	cp /var/lib/dpkg/status /tmp/dockerize/var/lib/dpkg/

# Install
FROM scratch AS postgres
COPY --from=builder /tmp/dockerize/ /
COPY .bashrc /var/pgsql/
COPY entrypoint /usr/bin/

ENV LANG en_US.UTF-8

ENV PATH /pgsql/bin:/usr/bin:/bin
ENV PGDATA /var/pgsql/data

RUN set -e; \
	mkdir -p $PGDATA; \
	chmod 700 $PGDATA; \
	chown -R 1000:1000 /var/pgsql; \
	chmod o+w -R /usr/lib/locale; \
	mkdir -m 1777 /tmp

WORKDIR /var/pgsql
USER 1000

STOPSIGNAL SIGINT
EXPOSE 5432

ENTRYPOINT [ "entrypoint" ]
CMD [ "postgres" ]
