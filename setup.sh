# cleanup any local vault instances
pkill vault
# load auth0 environment variables
source ./env

VAULT_UI=true 
VAULT_REDIRECT_ADDR=http://127.0.0.1:8200 
# start vault dev instance
nohup vault server \
    -log-level=trace \
    -dev \
    -dev-root-token-id=root \
    -dev-listen-address=127.0.0.1:8200 \
    -dev-ha \
    -dev-transactional &

# give vault a bit to launch
sleep 5

# create some secrets to work with
vault kv put secret/oidc works=true

# create policies
vault policy write manager manager.hcl
vault policy write reader reader.hcl

# enable oidc auth method
vault auth enable oidc

# configure oidc auth method
vault write auth/oidc/config \
        oidc_discovery_url="https://$AUTH0_DOMAIN/" \
        oidc_client_id="$AUTH0_CLIENT_ID" \
        oidc_client_secret="$AUTH0_CLIENT_SECRET" \
        default_role="reader"

vault write auth/oidc/role/reader \
        bound_audiences="$AUTH0_CLIENT_ID" \
        allowed_redirect_uris="http://localhost:8200/ui/vault/auth/oidc/oidc/callback" \
        allowed_redirect_uris="http://localhost:8250/oidc/callback" \
        user_claim="sub" \
        policies="reader"        


vault write auth/oidc/role/kv-mgr \
        bound_audiences="$AUTH0_CLIENT_ID" \
        allowed_redirect_uris="http://127.0.0.1:8200/ui/vault/auth/oidc/oidc/callback" \
        allowed_redirect_uris="http://localhost:8250/oidc/callback" \
        user_claim="sub" \
        policies="reader" \
        groups_claim="https://example.com/roles"


vault write identity/group name="manager" type="external" \
        policies="manager" \
        metadata=responsibility="Manage K/V Secrets"

GROUP_ID=`vault write identity/group name="manager" type="external" policies="manager" metadata=responsibility="Manage K/V Secrets" -format=json | jq -r .data.id`

# Get the mount accessor value of the oidc auth method and save it in accessor.txt file
vault auth list -format=json  \
        | jq -r '."oidc/".accessor' > accessor.txt

vault write identity/group-alias name="kv-mgr" \
        mount_accessor=$(cat accessor.txt) \
        canonical_id="$GROUP_ID"

# launch browser to authenticate w/ auth0
vault login -method=oidc

# test 
vault kv get secret/oidc 