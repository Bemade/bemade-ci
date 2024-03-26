FROM ubuntu:jammy as odoo

SHELL ["/bin/bash", "-xo", "pipefail", "-c"]


# Set Environment Variables
# Generate locale C.UTF-8 for postgres and general locale data
ENV LANG en_US.UTF-8
ENV ODOO_VERSION 17.0
# Set the default config file
ENV ODOO_RC /etc/odoo/odoo.conf
ENV PGHOST=postgres
ENV PGUSER=odoo
ENV PGPASSWORD=odoo
ENV PGDATABASE=odoo

# Retrieve the target architecture to install the correct wkhtmltopdf package
ARG TARGETARCH

# Install some deps, lessc and less-plugin-clean-css, and wkhtmltopdf

RUN apt update && \
    DEBIAN_FRONTEND=noninteractive \
    apt install -y \
        ca-certificates \
        curl \
        dirmngr \
        fonts-noto-cjk \
        gnupg \
        libssl-dev \
        libsasl2-dev \
        node-less \
        npm \
        python3-magic \
        python3-num2words \
        python3-odf \
        python3-pdfminer \
        python3-pip \
        python3-phonenumbers \
        python3-pyldap \
        python3-qrcode \
        python3-renderpm \
        python3-setuptools \
        python3-slugify \
        python3-vobject \
        python3-watchdog \
        python3-xlrd \
        python3-xlwt \
        xz-utils \
        build-essential \
        python3 \
        python3-venv \
        libxml2-dev \
        libxslt1-dev \
        libz-dev \
        libxmlsec1-dev \
        libldap2-dev \
        libjpeg-dev \
        libcups2-dev \
        swig \
        libffi-dev \
        libpq-dev \
        pkg-config \
        lsof && \
    if [ -z "${TARGETARCH}" ]; then \
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

# Install locales package and generate en_US.UTF-8
RUN apt-get update && apt-get install -y locales && rm -rf /var/lib/apt/lists/* \
    && locale-gen en_US.UTF-8

# Set environment variables to configure locale
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

# install latest postgresql-client
RUN echo 'deb http://apt.postgresql.org/pub/repos/apt/ jammy-pgdg main' > /etc/apt/sources.list.d/pgdg.list \
    && GNUPGHOME="$(mktemp -d)" \
    && export GNUPGHOME \
    && repokey='B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8' \
    && gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "${repokey}" \
    && gpg --batch --armor --export "${repokey}" > /etc/apt/trusted.gpg.d/pgdg.gpg.asc \
    && gpgconf --kill all \
    && rm -rf "$GNUPGHOME" \
    && apt-get update  \
    && apt-get install --no-install-recommends -y postgresql-client \
    && rm -f /etc/apt/sources.list.d/pgdg.list \
    && rm -rf /var/lib/apt/lists/*

# Install rtlcss (on Debian buster)
RUN npm install -g rtlcss

# Install Odoo from sources

COPY ./odoo /opt/odoo/
COPY ./enterprise/ /opt/odoo/enterprise/
COPY ./design-themes /opt/odoo/design-themes/
COPY ./odoo.conf /etc/odoo/

# Install Odoo and testing requirements in a virtual environment
RUN python3.10 -m venv /opt/odoo/venv \
    && source /opt/odoo/venv/bin/activate \
    && sed -i -e 's/^urllib3==.*/urllib3/' /opt/odoo/requirements.txt \
    && sed -i -e 's/^psycopg2==.*/psycopg2-binary/' /opt/odoo/requirements.txt \
    && echo "phonenumbers" >> /opt/odoo/requirements.txt \
    && pip install -r /opt/odoo/requirements.txt \
    && pip install manifestoo websocket-client==1.2.3 \
    && deactivate

# Install the run_tests command

COPY ./run_tests /usr/local/bin/

VOLUME ["/mnt/extra-addons", "/mnt/.repos", "/mnt/logs", "/mnt/extra-requirements"]
