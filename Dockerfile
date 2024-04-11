FROM ubuntu:jammy
ENV LANG C.UTF-8
USER root
SHELL ["/bin/bash", "-xo", "pipefail", "-c"]
ENV ODOO_VERSION 17.0
# Set the default config file
ENV ODOO_RC /etc/odoo/odoo.conf
# Set the default postgres info
ENV PGHOST=postgres
ENV PGUSER=odoo
ENV PGPASSWORD=odoo
ENV PGDATABASE=odoo
# Install basic debian packages
RUN set -x ; \
    apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    --no-install-recommends \
    apt-transport-https \
    build-essential \
    ca-certificates curl \
    ffmpeg \
    file \
    fonts-freefont-ttf \
    fonts-noto-cjk \
    gawk \
    gnupg \
    gsfonts \
    libldap2-dev \
    libjpeg9-dev \
    libsasl2-dev \
    libxslt1-dev \
    lsb-release \
    node-less \
    ocrmypdf \
    sed \
    sudo \
    unzip \
    xfonts-75dpi \
    zip \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# Install python-related debian packages
RUN set -x ; \
    apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    --no-install-recommends \
    python3 \
    python3-dbfread \
    python3-dev \
    python3-venv \
    python3-pip \
    python3-setuptools \
    python3-wheel \
    python3-markdown \
    python3-mock \
    python3-phonenumbers \
    python3-websocket \
    2to3 \
    python3-lib2to3 \
    python3-toolz \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Google Chrome

RUN curl -sSL \
    https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
    -o /tmp/chrome.deb \
    && apt-get update \
    && apt-get -y install --no-install-recommends /tmp/chrome.deb \
    && rm /tmp/chrome.deb

# Install phantomjs
RUN curl -sSL https://nightly.odoo.com/resources/phantomjs.tar.bz2 \
    -o /tmp/phantomjs.tar.bz2 \
    && tar xvfO /tmp/phantomjs.tar.bz2 \
        phantomjs-2.1.1-linux-x86_64/bin/phantomjs \
        > /usr/local/bin/phantomjs \
    && chmod +x /usr/local/bin/phantomjs \
    && rm -f /tmp/phantomjs.tar.bz2

# Install wkhtml
RUN if [ -z "${TARGETARCH}" ]; then \
        TARGETARCH="$(dpkg --print-architecture)"; \
    fi; \
    WKHTMLTOPDF_ARCH=${TARGETARCH} && \
    case ${TARGETARCH} in \
    "amd64") WKHTMLTOPDF_ARCH=amd64 && WKHTMLTOPDF_SHA=967390a759707337b46d1c02452e2bb6b2dc6d59  ;; \
    "arm64")  WKHTMLTOPDF_SHA=90f6e69896d51ef77339d3f3a20f8582bdf496cc  ;; \
    "ppc64le" | "ppc64el") WKHTMLTOPDF_ARCH=ppc64el && WKHTMLTOPDF_SHA=5312d7d34a25b321282929df82e3574319aed25c  ;; \
    esac \
    && curl -o wkhtmltox.deb -sSL https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-3/wkhtmltox_0.12.6.1-3.jammy_${WKHTMLTOPDF_ARCH}.deb \
    && echo ${WKHTMLTOPDF_SHA} wkhtmltox.deb | sha1sum -c - \
    && apt-get install -y --no-install-recommends ./wkhtmltox.deb \
    && rm -rf /var/lib/apt/lists/* wkhtmltox.deb

# Install nodejs and packages
RUN curl -sSL https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add - \
    && echo "deb https://deb.nodesource.com/node_20.x `lsb_release -c -s` main" > /etc/apt/sources.list.d/nodesource.list \
    && apt-get update \
    && apt-get install -y nodejs

RUN npm install -g rtlcss es-check eslint

# Install psql

RUN curl -sSL https://www.postgresql.org/media/keys/ACCC4CF8.asc \
    | apt-key add - \
    && echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -s -c`-pgdg main" \
    > /etc/apt/sources.list.d/pgclient.list \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y postgresql-client-12 \
    && rm -rf /var/lib/apt/lists/*

# Install Odoo from sources

COPY ./odoo /opt/odoo/
COPY ./odoo.conf /etc/odoo/


RUN python3 -m venv /opt/odoo/venv \
    && source /opt/odoo/venv/bin/activate \
    && sed -i -e 's/^urllib3==.*/urllib3/' /opt/odoo/requirements.txt \
    && sed -i -e 's/^psycopg2==.*/psycopg2-binary/' /opt/odoo/requirements.txt \
    && echo "phonenumbers" >> /opt/odoo/requirements.txt \
    && pip install --no-cache-dir "setuptools<=58" wheel \
    && pip install --no-cache-dir ebaysdk==2.1.5 pdf417gen==0.7.1 vatnumber \
    && pip install -r /opt/odoo/requirements.txt \
    && pip install manifestoo websocket-client==1.2.3 odoo-test-helper \
    && deactivate

# Note: runbot dockerfile  also installs coverage==4.5.4 astroid==2.4.2
#       pylint==2.5.0 flamegraph

# Install the run_tests command

COPY ./run_tests /usr/local/bin/

VOLUME ["/mnt/extra-addons", "/mnt/.repos", "/mnt/logs", \
"/mnt/extra-requirements", "/mnt/enterprise", "/mnt/design-themes"]
