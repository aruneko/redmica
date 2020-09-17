FROM ruby:2.6-slim-buster

ENV GOSU_VERSION=1.12
ENV TINI_VERSION=0.19.0

# Create no-root user for security
RUN groupadd -r -g 999 redmine && useradd -r -g redmine -u 999 redmine

# Install running dependencies
RUN set -eux; \
    apt update; \
    apt install -y --no-install-recommends \
      ghostscript \
      gsfonts \
      imagemagick \
    ; \
    rm -rf /var/lib/apt/lists/*

# Install gosu (running command without root user) and tini (killing zombie process)
RUN set -eux; \
    savedAptMark="$(apt-mark showmanual)"; \
    apt update; \
    apt install -y --no-install-recommends \
      dirmngr \
      gnupg \
      wget \
    ; \
    dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"; \
    wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch"; \
    wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc"; \
    export GNUPGHOME="$(mktemp -d)"; \
    gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4; \
    gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu; \
    gpgconf --kill all; \
    rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc; \
    chmod +x /usr/local/bin/gosu; \
    gosu nobody true; \
    \
    wget -O /usr/local/bin/tini "https://github.com/krallin/tini/releases/download/v$TINI_VERSION/tini-$dpkgArch"; \
    wget -O /usr/local/bin/tini.asc "https://github.com/krallin/tini/releases/download/v$TINI_VERSION/tini-$dpkgArch.asc"; \
    export GNUPGHOME="$(mktemp -d)"; \
    gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys 6380DC428747F6C393FEACA59A84159D7001A4E5; \
	  gpg --batch --verify /usr/local/bin/tini.asc /usr/local/bin/tini; \
	  gpgconf --kill all; \
	  rm -r "$GNUPGHOME" /usr/local/bin/tini.asc; \
	  chmod +x /usr/local/bin/tini; \
	  tini -h; \
	  \
    apt-mark auto '.*' > /dev/null; \
	  [ -z "$savedAptMark" ] || apt-mark manual $savedAptMark; \
	  apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
    rm -rf /var/lib/apt/lists/*

ENV RAILS_ENV production
WORKDIR /usr/src/redmine

# Make redmine user
ENV HOME /home/redmine
RUN set -eux; \
	[ ! -d "$HOME" ]; \
	mkdir -p "$HOME"; \
	chown redmine:redmine "$HOME"; \
	chmod 1777 "$HOME"

# Install gems
COPY Gemfile* ./

RUN set -eux; \
    savedAptMark="$(apt-mark showmanual)"; \
	  apt update; \
	  apt install -y --no-install-recommends \
		  freetds-dev \
		  gcc \
		  libpq-dev \
		  make \
		  patch \
	  ; \
	  rm -rf /var/lib/apt/lists/*; \
    \
    chown -R redmine:redmine ./; \
    find ./plugins -name Gemfile | xargs rm -rf; \
    gosu redmine bundle install --jobs "$(nproc)" --without development test; \
    chmod -R ugo=rwX Gemfile.lock "$GEM_HOME"; \
	  rm -rf ~redmine/.bundle; \
	  \
    apt-mark auto '.*' > /dev/null; \
	  [ -z "$savedAptMark" ] || apt-mark manual $savedAptMark; \
	  find /usr/local -type f -executable -exec ldd '{}' ';' \
	  	| awk '/=>/ { print $(NF-1) }' \
	  	| sort -u \
	  	| grep -v '^/usr/local/' \
	  	| xargs -r dpkg-query --search \
	  	| cut -d: -f1 \
	  	| sort -u \
	  	| xargs -r apt-mark manual \
	  ; \
	  apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false

# Install Redmine
COPY . .

RUN set -eux; \
    rm files/delete.me log/delete.me; \
    mkdir -p log public/plugin_assets tmp/pdf tmp/pids; \
    chown -R redmine:redmine ./; \
    echo 'config.logger = Logger.new(STDOUT)' > config/additional_environment.rb; \
    chmod -R ugo=rwX config db; \
    find log tmp -type d -exec chmod 1777 '{}' +

VOLUME /usr/src/redmine/files

COPY entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]

COPY start.sh /
EXPOSE 3000
CMD ["/start.sh"]

