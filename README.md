# nextcloud-dev-docker-compose

Nextcloud development environment using docker-compose for the [VO Federation app](https://github.com/nextcloud/vo_federation).

⚠ **DO NOT USE THIS IN PRODUCTION** Various settings in this setup are considered insecure and default passwords and secrets are used all over the place

Features

- ☁ Nextcloud
- 🔒 Nginx proxy with (local) SSL termination
- 💾 MySQL
- 💡 Redis
- 👥 LDAP with example user data
- ✉ Mailhog
- 🚀 Blackfire
- 📄 Collabora

## Getting started

Please follow the instructions to get the setup running. In the end the directory structure should look like this:

```
/home/ksandar/spaces/publicplan/Entwicklung/
├── nextcloud-docker-dev
├── nextcloud-server
└── vo_federation
```

Make sure you have `docker`, `docker-compose` and `git` working properly on your system before continuing.

### Nextcloud Code

Start by checking out this repository in your project home:

```
git clone https://github.com/smesterheide/nextcloud-docker-dev
```

Your default branch should be called `app/vo-federation`.

The Nextcloud code base needs to be available including the `3rdparty` submodule. To clone it from GitHub run:

```
git clone https://github.com/nextcloud/server.git nextcloud-server
cd nextcloud-server
git submodule update --init
pwd
```
The last command prints the path to the Nextcloud server directory.
Use it for setting the `REPO_PATH_SERVER` in the next step.

Beware that you might need to add other *remote* repositories for the Nextcloud server depending on the current state of core development. Support for VO Federation is subject to acceptance of pull requests. To add the development branch `vo-federation-features` for the Nextcloud server:

```
git remote add smesterheide https://github.com/smesterheide/nextcloud-server.git
git fetch smesterheide
git checkout -t smesterheide/vo-federation-features
```

Lastly from your project home add the `vo_federation` app repository:
```
git clone https://github.com/nextcloud/vo_federation
```

### Environment variables

A `.env` file should be created in the repository root, to keep configuration default on the dev setup:

```
cp example.env .env
```

The default configuration was slightly changed for the VO Federation app. Compare with upstream [example.env](https://github.com/juliushaertl/nextcloud-docker-dev/blob/master/example.env) and [bootstrap.sh](https://github.com/juliushaertl/nextcloud-docker-dev/blob/master/bootstrap.sh#L78).

* Replace `REPO_PATH_SERVER` with the path from above.
* Replace `ADDITIONAL_APPS_PATH` relative to `REPO_PATH_SERVER`
* Replace `STABLE_ROOT_PATH` with your project home

* Replace `VO_APP_PATH` with the VO Federation app directory

### Setting the PHP version to be used

The Nextcloud instance is setup to run with PHP 7.4 by default.
If you wish to use a different version of PHP, set the `PHP_VERSION` `.env` variable.

The variable supports the following values:

1. PHP 7.1: `71`
1. PHP 7.2: `72`
1. PHP 7.3: `73`
1. PHP 7.4: `74`
1. PHP 8.0: `80`

### Installing additional apps (optional)

```
mkdir -p nextcloud-server/apps-extra
git clone https://github.com/nextcloud/viewer.git nextcloud-server/apps-extra/viewer
git clone https://github.com/nextcloud/recommendations.git nextcloud-server/apps-extra/recommendations
git clone https://github.com/nextcloud/files_pdfviewer.git nextcloud-server/apps-extra/files_pdfviewer
git clone https://github.com/nextcloud/profiler.git nextcloud-server/apps-extra/profiler
```

### Starting the containers

- Start full setup: `docker-compose up`
- Minimum: `docker-compose up proxy nextcloud` (nextcloud mysql redis mailhog)

### Running stable versions (kept for reference - please read)

The docker-compose file provides individual containers for stable Nextcloud releases. In order to run those you will need a checkout of the stable version server branch to your workspace directory. Using [git worktree](https://blog.juliushaertl.de/index.php/2018/01/24/how-to-checkout-multiple-git-branches-at-the-same-time/) makes it easy to have different branches checked out in parallel in separate directories.

```
cd workspace/server
git worktree add ../stable23 stable23
cd ../stable23
git submodule update --init
```

After adding the worktree you can start the stable container using `docker-compose up -d stable23`. You can then add stable23.local to your `/etc/hosts` file to access it.

Git worktrees can also be used to have a checkout of an apps stable brach within the server stable directory.

```
cd workspace/server/apps-extra/text
git worktree add ../../../stable23/apps-extra/text stable23
```

### Running into errors

If your setup isn't working and you can not figure out the reason why, running
`docker-compose down -v` will remove the relevant containers and volumes,
allowing you to run `docker-compose up` again from a clean slate.

Some Docker images are built locally from a Dockerfile. You can rebuild them with the `--build` flag.

## 🔒 Local Reverse Proxy

The `proxy` service in `docker-compose.yml` is a preconfigured nginx server based on [nginx-proxy](https://hub.docker.com/r/nginxproxy/nginx-proxy).

> nginx-proxy sets up a container running nginx and [docker-gen](https://github.com/nginx-proxy/docker-gen). docker-gen generates reverse proxy configs for nginx and reloads nginx when containers are started and stopped.
> See [Automated Nginx Reverse Proxy for Docker](http://jasonwilder.com/blog/2014/03/25/automated-nginx-reverse-proxy-for-docker/) for why you might want to use this.

Basically any container with a `VIRTUAL_HOST` environment variable having exposed ports is added to the nginx proxy as a virtual host. For this to work all services are inspected by the `proxy` service via the `/var/run/docker.sock` socket. The nginx proxy then exposes port HTTP/80 and HTTPS/443 to the Docker host on 127.0.0.1 where it reverse proxies all other containers based on the HTTP `Host` header. 

In order to connect to Nextcloud instances `nextcloud`, `nextcloud2` and `nextcloud3` you have to tell your system to resolve their `VIRTUAL_HOST` address to localhost. Any user agent (like your browser) will send the corresponding hostname in the `Host` header to the `proxy` service.

If you have to make your Nextcloud instances available from the Internet during development, make sure to also read [Public Reverse Proxy](#-public-reverse-proxy).

### Resolving Nginx virtual hosts

You might need to add the domains to your `/etc/hosts` file:

```
127.0.0.1 nextcloud.local
127.0.0.1 collabora.local
```

This is assuming you have set `DOMAIN_SUFFIX_LOCAL=.local`

You can generate it through:

```
awk -v D=.local '/- [A-z0-9]+\${DOMAIN_SUFFIX_LOCAL}/ {sub("\\$\{DOMAIN_SUFFIX_LOCAL\}", D " 127.0.0.1", $2); print $2}' docker-compose.yml
```

### Local SSL support (optional)

To setup SSL support provide a proper DOMAIN_SUFFIX_LOCAL environment variable and put the certificates to ./data/ssl/ named by the domain name.

You can generate selfsigned certificates using:

```
cd data/ssl
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout  nextcloud.local.key -out nextcloud.local.crt
```

### dnsmasq to resolve wildcard domains (optional)

Instead of adding the individual container domains to `/etc/hosts` a local dns server like dnsmasq can be used to resolve any domain ending with the configured DOMAIN_SUFFIX_LOCAL in `.env` to localhost.

For dnsmasq adding the following configuration would be sufficient for `DOMAIN_SUFFIX_LOCAL=.local`:
```
address=/.local/127.0.0.1
```

### Use valid certificates trusted by your system (optional)

* Install mkcert https://github.com/FiloSottile/mkcert
* Go to `data/ssl`
* `mkcert nextcloud.local`

* `mv nextcloud.local-key.pem nextcloud.local.key`
* `mv nextcloud.local.pem nextcloud.local.crt`
* `docker-compose restart proxy`

## 🌍 Public Reverse Proxy

The VO Federation app requires users to authenticate against a Community AAI using OpenID Connect. The authentication flow involves a return URL that needs to be available on the public internet and registered with a Nextcloud instance.

### Word of caution

Exposing your development environment to the internet is generally a bad idea. Only continue if you understand the risks! 

* Lock down user accounts
* Secret domain names (obfuscation) do not offer any level of protection
* Only use this setup if you really have to. Ask yourself if you can accomplish the same task locally.
* Disconnect from the public reverse proxy after your day's work
* Destroy containers regularly

### Virtual private server

Here are the building blocks for the public reverse proxy:

* Cloud server / VPS with public IP address
* Public domain and control over DNS records
* VPN Gateway
* Nginx reverse proxy
* Letsencrypt / Certbot for remote SSL termination

The setup allows multiple users (developers) to have any number of Nextcloud instances exposed at the same time, eg.

* Alice's nextcloud.home.arpa is mapped to alice.nextcloud.example.com
* Alice's nextcloud2.home.arpa is mapped to alice2.nextcloud.example.com
* Bob's nextcloud.home.arpa is mapped to bob.nextcloud.example.com

The connection from your development machine to the cloud server is established through VPN. The VPN client will create a virtual network interface and will be assigned an IP address on the server network 192.168.254.0/24. Each user wanting to expose their development environment on the public reverse proxy needs to be configured in advance with matching subdomains on the server and home Docker environment.

Locally the environment variables `DOMAIN_SUFFIX_PUBLIC` and `PUBLIC_ALIAS`es control the subdomains that are passed though by the public reverse proxy. 

For the server setup consult the corresponding VPS [README.md](https://github.com/smesterheide/nextcloud-docker-env/tree/app/vo-federation/vps).

### VPN connection

The VPN server will assign static IP addresses to its clients. No default routes will be pushed either (Split tunneling):

```
192.168.254.1 via 192.168.254.2 dev tun0 
192.168.254.2 dev tun0 proto kernel scope link src 192.168.254.1 
```

To connect:

```
# openvpn sme.ovpn
```

## ✉ Mail

Sending/receiving mails can be tested with [mailhog](https://github.com/mailhog/MailHog) which is available on ports 1025 (SMTP).

To use the webui, add `127.0.0.1 mail.local` to your `/etc/hosts` and open [mail.local](http://mail.local).

## 🚀 Blackfire

Blackfire needs to use a hostname/ip that is resolvable from within the blackfire container. Their free version is [limited to local profiling](https://support.blackfire.io/troubleshooting/hack-edition-users-cannot-profile-non-local-http-applications) so we need to browse Nextcloud though its local docker IP or add the hostname to `/etc/hosts`.

### Using with curl

```
alias blackfire='docker-compose exec -e BLACKFIRE_CLIENT_ID=$BLACKFIRE_CLIENT_ID -e BLACKFIRE_CLIENT_TOKEN=$BLACKFIRE_CLIENT_TOKEN blackfire blackfire'
blackfire curl http://192.168.21.8/
```

## 👥 LDAP

The LDAP sample data is based on https://github.com/rroemhild/docker-test-openldap and extended with randomly generated users/groups. For details see [data/ldap-generator/](https://github.com/juliushaertl/nextcloud-docker-dev/tree/master/data/ldap-generator). LDAP will be configured automatically if the ldap container is available during installation.

Example users are: `leela fry bender zoidberg hermes professor`. The password is the same as the uid.

Useful commands:

```
docker-compose exec ldap ldapsearch -H 'ldap://localhost' -D "cn=admin,dc=planetexpress,dc=com" -w admin -b "dc=planetexpress,dc=com" "(&(objectclass=inetOrgPerson)(description=*use*))"
```

## SAML

```
docker-compose up -d proxy nextcloud saml
```

- uid mapping: `urn:oid:0.9.2342.19200300.100.1.1`
- idp entity id: `https://sso.local.dev.bitgrid.net/simplesaml/saml2/idp/metadata.php`
- single sign on service url: `https://sso.local.dev.bitgrid.net/simplesaml/saml2/idp/SSOService.php`
- single log out service url: `https://sso.local.dev.bitgrid.net/simplesaml/saml2/idp/SingleLogoutService.php`
- use certificate from docker/configs/var-simplesamlphp/cert/example.org.crt
  ```
  -----BEGIN CERTIFICATE-----
  MIICrDCCAhWgAwIBAgIUNtfnC2jE/rLdxHCs2th3WaYLryAwDQYJKoZIhvcNAQEL
  BQAwaDELMAkGA1UEBhMCREUxCzAJBgNVBAgMAkJZMRIwEAYDVQQHDAlXdWVyemJ1
  cmcxFDASBgNVBAoMC0V4YW1wbGUgb3JnMSIwIAYDVQQDDBlzc28ubG9jYWwuZGV2
  LmJpdGdyaWQubmV0MB4XDTE5MDcwMzE0MjkzOFoXDTI5MDcwMjE0MjkzOFowaDEL
  MAkGA1UEBhMCREUxCzAJBgNVBAgMAkJZMRIwEAYDVQQHDAlXdWVyemJ1cmcxFDAS
  BgNVBAoMC0V4YW1wbGUgb3JnMSIwIAYDVQQDDBlzc28ubG9jYWwuZGV2LmJpdGdy
  aWQubmV0MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDHPZwU+dAc76yB6bOq
  0AkP1y9g7aAi1vRtJ9GD4AEAsA3zjW1P60BYs92mvZwNWK6NxlJYw51xPak9QMk5
  qRHaTdBkmq0a2mWYqh1AZNNgCII6/VnLcbEIgyoXB0CCfY+2vaavAmFsRwOMdeR9
  HmtQQPlbTA4m5Y8jWGVs1qPtDQIDAQABo1MwUTAdBgNVHQ4EFgQUeZSoGKeN5uu5
  K+n98o3wcitFYJ0wHwYDVR0jBBgwFoAUeZSoGKeN5uu5K+n98o3wcitFYJ0wDwYD
  VR0TAQH/BAUwAwEB/zANBgkqhkiG9w0BAQsFAAOBgQA25X/Ke+5dw7up8gcF2BNQ
  ggBcJs+SVKBmPwRcPQ8plgX4D/K8JJNT13HNlxTGDmb9elXEkzSjdJ+6Oa8n3IMe
  vUUejXDXUBvlmmm+ImJVwwCn27cSfIYb/RoZPeKtned4SCzpbEO9H/75z3XSqAZS
  Z1tiHzYOVtEs4UNGOtz1Jg==
  -----END CERTIFICATE-----
  ```
- cn `urn:oid:2.5.4.3`
- email `urn:oid:0.9.2342.19200300.100.1.3`

### Environment based SSO

A simple approach to test environment based SSO with the user_saml app is to use apache basic auth with the following configuration:

```

<Location /login>
	AuthType Basic
	AuthName "SAML"
	AuthUserFile /var/www/html/.htpasswd
	Require valid-user
</Location>
<Location /index.php/login>
	AuthType Basic
	AuthName "SAML"
	AuthUserFile /var/www/html/.htpasswd
	Require valid-user
</Location>
<Location /index.php/apps/user_saml/saml/login>
	AuthType Basic
	AuthName "SAML"
	AuthUserFile /var/www/html/.htpasswd
	Require valid-user
</Location>
<Location /apps/user_saml/saml/login>
	AuthType Basic
	AuthName "SAML"
	AuthUserFile /var/www/html/.htpasswd
	Require valid-user
</Location>
```

## Development

### OCC

Run inside of the Nextcloud container:
```
set XDEBUG_CONFIG=idekey=PHPSTORM
sudo -E -u www-data php -dxdebug.remote_host=192.168.21.1 occ
```

### Useful commands

- Restart apache to reload php configuration without a full container restart: `docker-compose kill -s USR1 nextcloud`
- Access to mysql console: `mysql -h $(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' nextcloud_database-mysql_1) -P 3306 -u nextcloud -pnextcloud`
- Run an LDAP search: `ldapsearch -x -H ldap://$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' nextcloud_ldap_1) -D "cn=admin,dc=planetexpress,dc=com" -w admin -b "dc=planetexpress,dc=com" -s subtree <filter> <attrs>`

## Keycloak

- Keycloak is using ldap as a user backend (make sure the ldap container is also running)
- `occ user_oidc:provider Keycloak -c nextcloud -s 09e3c268-d8bc-42f1-b7c6-74d307ef5fde -d https://keycloak.local.dev.bitgrid.net/auth/realms/Example/.well-known/openid-configuration`
- https://keycloak.local.dev.bitgrid.net/auth/realms/Example/.well-known/openid-configuration
- nextcloud
- 09e3c268-d8bc-42f1-b7c6-74d307ef5fde

## Global scale

```
docker-compose up -d proxy portal gs1 gs2 lookup database-mysql
```

Users are named the same as the instance name, e.g. gs1, gs2

## Changes from upstream juliushaertl/nextcloud-docker-dev

### Project-level bootstrap.sh

The original project comes with two bootstrap scripts. One is mandatory as it is the Docker entrypoint for the Nextcloud instances and manages the initial installation of Nextcloud. The second is a [convenience script](https://github.com/juliushaertl/nextcloud-docker-dev/blob/master/bootstrap.sh) for the user to set up the workspace. The latter was removed and the user is required to follow the manual steps to getting started.

### Nextcloud Docker entrypoint bootstrap.sh

The Nextcloud Docker image is built locally to allow changes to the files added to the image where necessary.

The Nextcloud containers rely on `nginx-proxy` environment variable `VIRTUAL_HOST` for their unique instance names. Adding a public reverse proxy to the mix, the `VIRTUAL_HOST` variable now takes up multiple hostnames separated by comma.

Therefore a new variable `NEXTCLOUD_VIRTUAL_HOST` was introduced which replaces occurences of `VIRTUAL_HOST` in the Docker entrypoint `bootstrap.sh`.

### Disabled Containers

* Postgres
  * _disabled in favor of MySQL_
* Blackfire.io
  * Blackfire APM. Observability from Development to Production
  * Monitor, profile and test your application 
  * _installed with Dockerfile; currently disabled_
* notify_push
  * Update notifications for nextcloud clients
* Global Scale, Lookup Server

### Removed Containers

* HAProxy
  * Round robin HTTP load balancer for nextcloud, nextcloud2
* Nextcloud stable releases other than stable24
* SMB
* Collabora, OpenOffice
* MinIO
  * MinIO offers high-performance, S3 compatible object storage
* Elasticsearch
* ClamAV
* imaginary
  * Fast HTTP microservice written in Go for high-level image processing backed




