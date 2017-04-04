# acme-tiny-scripts

This is a suite of tiny, auditable scripts that you can throw on your server to
manage keys, certificate requests and [Let's Encrypt](https://letsencrypt.org/)
certificates using [acme-tiny](https://github.com/diafygi/acme-tiny/).

# installation

```
git clone https://github.com/mat813/acme-tiny-scripts.git
cd acme-tiny-scripts
cp config.sh.sample config.sh
```

Edit the values in `config.sh` according to your installation.  All three path
should be owned by the user running the scripts, the mode of the private path
should be 0711.  The durations are in days.

# scripts

## `gen_key.sh name`

This script is used to generate keys for 1) the account, 2) the certificate and
requests.  It takes only one argument, the name associated with the key.  The
same name will be used for the certificate request, and the certificate.  In
the end, you will get a `<name>.crt`

*When you first run everything, you must generate an account key, it is not
used by any certificate, only for communication between the scripts and
letsencrypt.  Start by:*

```shell
$ ./gen_key.sh account
Generating RSA private key, 4096 bit long modulus
...................................++
..............++
e is 65537 (0x10001)
$
```

Now, you can create the key to your first certificate request:

```shell
$ ./gen_key.sh example
Generating RSA private key, 4096 bit long modulus
............................++
...........................................++
e is 65537 (0x10001)
$
```

## `gen_csr.sh name domain [domain...]`

This script generates a Certificate Signing Request in the private directory.
It takes two, or more, arguments, the first is the name, the same as the one
used for the key generation, and the other are the domains you need your
certificate to have:

```shell
$ ./gen_csr.sh example examples.com www.examples.com examples.net www.examples.net
$
```

You can check that it does contain the right domains with:

```shell
$ openssl req -noout -text < /etc/ssl/private/letsencrypt/example.csr |grep DNS
                DNS:examples.com, DNS:www.examples.com, DNS:examples.net, DNS:www.examples.net
```

### DANE/TLSA

The script will also generate a /etc/ssl/public/letsencrypt/example.tlsa file
with HTTPS TLSA (`_443._tcp.domain.`) records for all the domains passed as
arguments.  If you are using the certificates for other purpose than HTTPS, you
will have to change the port number.

## `gen_one.sh name`

This script uses the key and CSR generated during the previous steps and calls
acme-tiny.py to get a valid certificate from Let's Encrypt.

At this point, you need to have setup your web server to point the
`/.well-known/acme-challenge/` directory to the challenge path of the
configuration file.  See [configuring your web
server](#configuring-your-web-server) for more informations.

```shell
$ ./gen_one.sh example
Parsing account key...
Parsing CSR...
Registering account...
Already registered!
Verifying example.com...
example.com verified!
Verifying www.example.com...
www.example.com verified!
Verifying example.net...
example.net verified!
Verifying www.example.net...
www.example.net verified!
Signing certificate...
Certificate signed!
$
```

If all went well, you now have a `example.crt` file in the public directory.
You can check that it does contain the requested domains:

```shell
$ openssl x509 -noout -text -in /etc/ssl/public/letsencrypt/example.crt |grep DNS
                DNS:examples.com, DNS:www.examples.com, DNS:examples.net, DNS:www.examples.net
```

You can now configure the SSL bits of your web web server with that certificate
and the associated key.

There are actually two files that are generated, the `<name>.crt` that only
contains the certificate, and a `<name>.bundle` that contains both the
certificate, and the intermediate certificate from Let's Encrypt.  The
intermediate certificate is also stored as intermediate.pem in the public
directory.

### Configuring your web server

First, note that Let's Encrypt will look for the challenge over *http* not
https, so either your web server must be able to give the answer over http, or
it must redirect to https, and in that case, the certificate must be valid.

In the following examples, I will describe serving the challenges over http.  I
prefer this method because it still works if your certificates are invalid, for
example, if you let the expire.

#### Apache

To be able to serve the challenge over http, you only need to add an `Alias` directive

```apache
<VirtualHost *:80>
        ServerName www.example.net
        Alias /.well-known/acme-challenge/ /usr/local/www/challenges/
	<Directory /usr/local/www/challenges/>
		Require all granted
	</Directory>
	[rest of your VirtualHost configuration]
</VirtualHost>
```

If your `VirtualHost` contains a `RedirectPermanent /
https://www.examples.net/` then you will need to be a bit more subtle with how
you configure things so that the challenges work:

```apache
<VirtualHost *:80>
        ServerName www.example.net
        Alias /.well-known/acme-challenge/ /usr/local/www/challenges/
	<Directory /usr/local/www/challenges/>
		Require all granted
	</Directory>
        RedirectMatch 301 ^(?!/\.well-known/acme-challenge/).* https://www.example.net$0
</VirtualHost>
```

#### Nginx

```nginx
    server {
        listen       *:80;
        listen       [::]:80;
        server_name  www.example.net;

        location /.well-known/acme-challenge/ {
            alias /usr/local/www/challenges/;
            try_files $uri =404;
        }

	[rest of your server configuration]
    }
```

If your server configuration contains a `return 301
https://www.example.net$request_uri;` then you will need to bit a bit more
subtle with how you configure things so that the challenges work:

```nginx
    server {
        listen       *:80;
        listen       [::]:80;
        server_name  www.example.net;

        location /.well-known/acme-challenge/ {
            alias /usr/local/www/challenges/;
            try_files $uri =404;
        }

        location / {
                return 301 https://www.example.net$request_uri;
        }
    }
```

## `regen.sh service [service...]`

This script should be run, via cron, every day, to regenerate outdated
certificates.  Certificates are considered outdated when their expiration date
is less than $renew days from now, the default is 20 days.

Before you add a cron entry with `0 0 * * * /some/path/regen.sh`.  I said once
a day, not "at midnight".  If everybody does that, the Let's Encrypt servers
will be hammered on the first of each months at the top of every hour, and
won't do a thing on days 2 to 31.

So, add a cron entry, with, say, `15 22 * * * /some/path/regen.sh`, but not
that one either, choose your own.

It also take as arguments the services to reload. (With the service command,
that may, or may not, exist, on your OS.)
It also uses sudo to run the commands, but you may tinker with the end of that
script to fit your needs.

## `check_expire.sh`

This is a nagios plugin that will check that all the certificates in the public
directory have an expiration date of at least $warning days in the future,
default 15, give a warning if they have less, and become critical if it goes
below $critical days, default 10.

# notes

I am a FreeBSD user, so, all this works just fine on FreeBSD, YMMV.

# /!\ caveats /!\

The `regen.sh` script is ran from cron, and it runs acme-tiny.  The
acme-tiny script's shebang contains `/usr/bin/env python` so python must
either be in cron's PATH, or you must change acme-tiny's shebang to point to
the correct python PATH.
