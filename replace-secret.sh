#!/bin/bash
if [ -f "packages/cli/src/modules/external-secrets.ee/providers/vault.ts" ]; then
    sed -i "s/hvs\.2OCsZxZA6Z9lChbt0janOOZI/hvs_example_token/g" "packages/cli/src/modules/external-secrets.ee/providers/vault.ts"
fi

