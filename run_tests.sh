#!/bin/bash

ADDONS_LIST=$(manifestoo --select-addons-dir="$GITHUB_WORKSPACE" --odoo-series=17.0 list --separator=,)

odoo -c /etc/odoo/odoo.conf -d test -i "$ADDONS_LIST" --test-enable --stop-after-init
