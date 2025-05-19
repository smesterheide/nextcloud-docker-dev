#!/bin/bash
export OC_PASS="${OC_PASS_ADMIN:-admin}"
occ user:resetpassword --password-from-env admin

occ config:app:set files_sharing incoming_server2server_group_share_enabled --value="yes"
occ config:app:set files_sharing outgoing_server2server_group_share_enabled --value="yes"

INSTANCENAME=$(echo "$VIRTUAL_HOST" | cut -d '.' -f1)
DOMAIN_SUFFIX=".$(echo "$VIRTUAL_HOST" | cut -d '.' -f2-)"

if [ "$INSTANCENAME" == "nextcloud" ]; then
    echo "Adding Keycloak as an OIDC provider for nexcloud, trusting nexcloud2, nextcloud3"
    occ vo_federation:provider:add Keycloak \
        --clientid="nextcloud" \
        --clientsecret="nextcloud" \
        --authorization-endpoint="https://keycloak${DOMAIN_SUFFIX}/realms/nextcloud/protocol/openid-connect/auth" \
        --token-endpoint="https://keycloak${DOMAIN_SUFFIX}/realms/nextcloud/protocol/openid-connect/token" \
        --jwks-endpoint="https://keycloak${DOMAIN_SUFFIX}/realms/nextcloud/protocol/openid-connect/certs" \
        --userinfo-endpoint="https://keycloak${DOMAIN_SUFFIX}/realms/nextcloud/protocol/openid-connect/userinfo" \
        --scope="openid email profile groups" \
        --mapping-uid="sub" \
        --mapping-display-name="preferred_username" \
        --mapping-groups="groups" \
        --regex-pattern=".*" \
        --trusted-instance="https://nextcloud2${DOMAIN_SUFFIX}" \
        --trusted-instance="https://nextcloud3${DOMAIN_SUFFIX}"
fi

if [ "$INSTANCENAME" == "nextcloud2" ]; then
    echo "Adding Keycloak as an OIDC provider for nexcloud2, trusting nexcloud, nextcloud3"
    occ vo_federation:provider:add Keycloak \
        --clientid="nextcloud" \
        --clientsecret="nextcloud" \
        --authorization-endpoint="https://keycloak${DOMAIN_SUFFIX}/realms/nextcloud/protocol/openid-connect/auth" \
        --token-endpoint="https://keycloak${DOMAIN_SUFFIX}/realms/nextcloud/protocol/openid-connect/token" \
        --jwks-endpoint="https://keycloak${DOMAIN_SUFFIX}/realms/nextcloud/protocol/openid-connect/certs" \
        --userinfo-endpoint="https://keycloak${DOMAIN_SUFFIX}/realms/nextcloud/protocol/openid-connect/userinfo" \
        --scope="openid email profile groups" \
        --mapping-uid="sub" \
        --mapping-display-name="preferred_username" \
        --mapping-groups="groups" \
        --regex-pattern=".*" \
        --trusted-instance="https://nextcloud${DOMAIN_SUFFIX}" \
        --trusted-instance="https://nextcloud3${DOMAIN_SUFFIX}"
fi

if [ "$INSTANCENAME" == "nextcloud2" ]; then
    echo "Adding Keycloak as an OIDC provider for nexcloud3, trusting nexcloud, nextcloud2"
    occ vo_federation:provider:add Keycloak \
        --clientid="nextcloud" \
        --clientsecret="nextcloud" \
        --authorization-endpoint="https://keycloak${DOMAIN_SUFFIX}/realms/nextcloud/protocol/openid-connect/auth" \
        --token-endpoint="https://keycloak${DOMAIN_SUFFIX}/realms/nextcloud/protocol/openid-connect/token" \
        --jwks-endpoint="https://keycloak${DOMAIN_SUFFIX}/realms/nextcloud/protocol/openid-connect/certs" \
        --userinfo-endpoint="https://keycloak${DOMAIN_SUFFIX}/realms/nextcloud/protocol/openid-connect/userinfo" \
        --scope="openid email profile groups" \
        --mapping-uid="sub" \
        --mapping-display-name="preferred_username" \
        --mapping-groups="groups" \
        --regex-pattern=".*" \
        --trusted-instance="https://nextcloud${DOMAIN_SUFFIX}" \
        --trusted-instance="https://nextcloud2${DOMAIN_SUFFIX}"
fi

# Reload mounted crontab 
crontab /etc/nc-cron.conf
