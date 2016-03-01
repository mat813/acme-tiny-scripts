# acme-tiny-scripts

This is a suite of tiny, auditable scripts that you can throw on your server to
manage keys, certificate requests and [Let's Encrypt](https://letsencrypt.org/)
certificates using [acme-tiny](https://github.com/diafygi/acme-tiny/).

## installation

```
git clone https://github.com/mat813/acme-tiny-scripts.git
cd acme-tiny-scripts
cp lets_path.sh.sample lets_path.sh
```

Edit the paths in the PATH section of `lets_path.sh` according to your
installation.  All three path should be owned by the user running the scripts,
the mode of the private path should be 0711.

## scripts

### `gen_key.sh name`

This script is used to generate keys for 1) the account, 2) the certificate and
requests.  It takes only one argument, the name associated with the key.  The
same name will be used for the certificate request, and the certificate.  In
the end, you will get a `<name>.crt`

When you first run everything, you must start by:

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

### `gen_csr.sh name domain [domain...]`

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

### `gen_one.sh name`

This script uses the key and CSR generated during the previous steps and calls
acme-tiny.py to get a valid certificate from Let's Encrypt.

At this point, you need to have setup your web server to point the
`/.well-known/acme-challenge/` directory to the challenge path of the
configuration file.

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

### `regen.sh service [service...]`

This script should be run, via cron, once a month, to regenerate the certificates.

Before you add a cron entry with `0 0 1 * * /some/path/regen.sh`, I said once a
month, not at midnight of the first day of the month.  If everybody does that,
the Let's Encrypt servers will be hammered on the first of each months at the
top of every hour, and won't do a thing on days 2 to 31.

So, add a cron entry, with, say, `15 22 12 * * /some/path/regen.sh`, but not
that one either, choose your own.

It also take as arguments the services to reload. (With the service command,
that may, or may not, exist, on your OS.)
It also uses sudo to run the commands, but you may tinker with the end of that
script to fit your needs.

### `check_expire.sh`

This is a nagios plugin that will check that all the certificates in the public
directory have an expiration date of at least 50 days in the future, give a
warning if they have less, and become critical if it goes below 25 days.

## notes

I am a FreeBSD user, so, all this works just fine on FreeBSD, YMMV.

## /!\ caveats /!\

The `regen.sh` script is ran from cron, and it runs acme-tiny.  The
acme-tiny script's shebang contains `/usr/bin/env python` so python must
either be in cron's PATH, or you must change acme-tiny's shebang to point to
the correct python PATH.
