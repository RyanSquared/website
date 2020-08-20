+++
author = "Ryan Heywood"
title = "Thoughts on the Recent (5.7.0) NPM Bug"
date = "2018-02-23"
description = "A breakdown of the implications of running NPM as root"
tags = [
    "security",
    "linux",
    "software",
    "npm"
]
featured = false
+++

There was a bug in NPM as of version 5.7.0. In short, running as a user but
using NPM sudo escalation would use the identity of the user as the owner of
files modified by NPM, rather than the identity of root. This would happen for
any file or directory that NPM would modify, when as root, AIUI.

<!--more-->

Relevant bug report [here][gh-issue-npm-npm-19883].

> This issue has been happening ever since 5.7.0 was released a few hours ago.
It seems to have completely broken my filesystem permissions and caused me to
have to manually fix the permissions of critical files and folders. I believe
that it is related to the commit 94227e1 which is traversing and running chown
on the wrong, often critical, filesystem files and folders.
>
> By running sudo npm under a non-root user (root users do not have the same
effect), filesystem permissions are being heavily modified. For example, if I
run `sudo npm --help` or `sudo npm update -g`, both commands cause my
filesystem to change ownership of directories such as `/etc`, `/usr`, `/boot`,
and other directories needed for running the system. It appears that the
ownership is recursively changed to the user currently running npm.
>
> I found that a selection of directories in `/` were owned by a non-root user
after running `sudo npm` and many binaries in `/usr/bin` stopped working as
their permissions were changed. People experiencing this bug will likely have
to fully reinstall their system due to this update.
>
> `npm update -g` as `root`:
>
> No output, all packages up to date. Likely still causes a `chown` to be run
silently to `root:root`.
`drwxr-xr-x 10 root root 129 Feb 22 03:39 /usr`
>
> Then doing a `su jared` (a non-root user):
> 
> `sudo npm update -g` as `jared`:
>
> Sometimes `EACCES` or `EPERM` output, almost always corrupts the filesystem.
`drwxr-xr-x 10 jared jared 129 Feb 22 03:39 /usr`

Some significant and relevant bits of information can be extracted from this:

- A flaw in `npm` broke multiple users systems.
- `npm` is commonly run in a "global" mode that requires `sudo`.

## I think this is unacceptable.

We, as people who acknowledge that there are flaws in software, should not be
as trusting as we are. We shouldn't give programs the ability to mutilate our
system and potentially make it unusable, just because we want to install 
`lolcat` to make things show up as a nice and pretty rainbow colour (yes,
lolcat is ruby, not JS, but that's not the point).

We shouldn't be using software put in the hands of people that we don't trust.
We shouldn't be giving root permissions to programs that don't need it. If
a program doesn't need to be installed system-wide, it shouldn't need to be
run with `sudo`.

With an organization I work with - Hashbang, Inc. - we let users run amok on a
shared system, doing as they please. These users typically want to install some
things to make their lives easier, but I'm ~~lazy~~ security-oriented, so we
needed a way to let users install software without being able to destroy the
system.

## A solution

We need a directory where users can put things that don't need to be permanent,
that shouldn't be able to affect other users, that can be replaced if needed,
and don't need root permissions which - if taken away - can cause the system
to become irreparably broken. This directory would be useful for storing their
configuration files, their media, and their programs. Wait... That's just-

__`$HOME` - The directory built by you, for you.__

Users have their own directory. They're allowed to put whatever they want in
that directory. They can store NSA secrets, massive amounts of material used
for personal satisfaction, games, and other things. There's no reason we can't
also include binaries, libraries, and configuration files in that directory.

**But, NPM requires root!**

Actually, while a lot of these binary package installers mostly tell you to use
`sudo` when installing things (with exception to Rust and Go, bless them) you
can still make them use your home directory through some simple RC changes.

I've set up an example below that you can copy, for Lua, Python, Ruby, and
NodeJS. You can look up relevant examples for other software.

```sh
# Lua
# Use `--local` when invoking the aliases to get your HOME path.
alias luarocks-5.1="lua5.1 /usr/bin/luarocks"
alias luarocks-5.2="lua5.2 /usr/bin/luarocks"
alias luarocks-5.3="lua5.3 /usr/bin/luarocks"
# Need to do 5.1 last, as it adds to LUA_PATH, which would be picked up by the
# other PATH commands.
eval `lua5.3 /usr/bin/luarocks --bin path`
eval `lua5.2 /usr/bin/luarocks --bin path`
eval `lua5.1 /usr/bin/luarocks --bin path`

# Python, and a few other things
# For Python's package manager `pip`, use the `--user` flag when installing.
export PATH="$HOME/.local/bin:$PATH"

# Ruby
# Ruby automatically installs as user, but most systems don't use the
# Ruby binary installation directory for loading binaries.
export PATH="$HOME/.gem/bin:$PATH"

# Node.js
export PATH="$HOME/.npm_packages/bin:$PATH"
export NODE_PATH="$HOME/.npm_packages/lib/node_modules"
export NPM_CONFIG_PREFIX="$HOME/.npm_packages"
```

## User Services

Programs that don't need to interact with hardware can often be run as your
own user. I've recently moved to systemd user units for my Hashbang setup, so
I'm able to automatically start my personal nginx webserver when I first
connect, and on your systems you can use `loginctl enable-linger <user>` to set
[libpam-systemd][libpam-systemd] to start on system startup.

I'll provide the configuration I use for my personal webserver, as an example
of how to start nginx on system startup. You can use this for any software,
like a music player. Additionally, you can get rid of a dependency on `cron` by
using [systemd timers][systemd-timers-post], as most cron implementations run
outside of the users' session preventing functions like resource limiting from
working.

EDIT-2020-08-15: Rewrite to be less snarky.

[gh-issue-npm-npm-19883]: https://github.com/npm/npm/issues/19883
[libpam-systemd]: https://packages.debian.org/stretch/libpam-systemd
[systemd-timers-post]: {{< ref "2018-03-20-using-systemd-timers.md" >}}
