# Container image to run Bemade CI tests

⚠️ These images are meant for running CI tests of Odoo addons developed by
Bemade inc. They are *not* intended for any other purpose, and in particular
they are not fit for running Odoo in production. If you decide to base your own
CI on these images, be aware that, while we will not break things without
reason, we will prioritize ease of maintenance for Bemade over backward
compatibility. ⚠️

These images were developed with heavy influence from the Odoo Community Association's
[oca-ci](https://github.com/oca/oca-ci) project as well as Odoo's own 
[Docker project](https://github.com/odoo/docker).

## Guarantees

These images provide the following guarantees:

- Odoo runtime dependencies are installed (`wkhtmltopdf`, `lessc`, etc).
- Odoo source code is in `/opt/odoo`.
- Odoo is installed in editable mode in a virtualenv isolated from system python packages.
- The Odoo configuration file exists at `$ODOO_RC`.
- Prerequisites for running Odoo tests are installed in that virtualenv
  (this notably includes `websocket-client` and the chrome browser for running
  browser tests).
- Python requirements in files found in /mnt/extra-requirements are installed in the Odoo
  virtualenv.
- Addons in /mnt/extra-addons are available to the Odoo installation.

## Requirements

This image was built with the assumption that tests would be run in an environment where
a Postgresql host is available. The simplest way to run tests is with a simple Docker
Compose file such as the examples found [here](https://github.com/bemade/bemade-ci/blob/17.0/compose.yml)
and [here](https://github.com/bemade/bemade-ci/blob/17.0/compose-manual.yml). Note that
these examples assume that there are some directories present in the local filesystem and
will not function "out of the box". Please change the mount locations for logs, extra-addons
and extra-requirements according to your needs.

## Running Tests

### Automatic Mode

Once everything is set up correctly, you can run the tests for all addons in the extra-addons
directory by executing a simple `docker compose up -d` command where your compose.yml file is
located. This will set up virtualenv requirements and rotate through testing each addon individually
in a new test database. Essentially, it will run the command
`odoo-bin -i <addon> --test-enable -d <new-db> --stop-after-init` (along with a few more options
to avoid port collisions and set the logfile path, etc.). Tests are run on a maximum of 3 Odoo 
processes in parallel. Running tests this way is useful for nightly testing of all modules, for example.

### Manual Mode

If you need to run tests without running through all addons in the extra-addons directory, you will
want to use a variation on the compose-manual.yml to run your test instance. This is achieved with
the following commands, run from the location of the compose-manual.yml file:

  docker compose -f compose-manual.yml up -d
  docker exec -it odoo /bin/bash
  run_tests -s -a <module_name>
