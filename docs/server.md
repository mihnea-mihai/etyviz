## How to configure the server

The following steps assume you have root access to a Linux machine.
Some steps may only be applicable for Debian machines.

### Create the `server` user

Connect to `root` and create the `server` user.

```sh
adduser server --disabled-password --comment ''
```

Switch to the newly created user, then add your public key.

```sh
su server
```

```sh
cd ~
mkdir .ssh
echo "${PUBLIC KEY CONTENT}" > .ssh/authorized_keys
```

Replace with the content of your public key.
