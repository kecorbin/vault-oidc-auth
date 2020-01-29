# vault-oidc-auth

Some automation to quickly demo https://learn.hashicorp.com/vault/identity-access-management/oidc-auth

## Pre-requisites

1. Download and install vault in your path https://www.vaultproject.io/downloads/

2. Setup an Auth0 account and configure per the instruction in the learn guide from above. 

3. Rename `env.example` to `env` and fill in the variables according to your application from Step 1

## Running

```
./setup.sh
```

## Cleanup

```
pkill vault
```