+++
author = "Ryan Heywood"
title = "Using systemd Timers Instead of crontabs"
date = "2018-03-20"
description = "An explanation of how systemd timers work"
tags = [
    "linux",
    "software",
    "systemd",
    "cron"
]
featured = false
+++

The software `systemd` is preinstalled on most Linux systems and is commonly
known for being ~~the destroyer of worlds~~ ~~a constant cause of problems~~
a rather notoriously difficult system management daemon. I'd like to discuss
some reasons why both timers are essential to someone's workflow as well as why
systemd should probably be chosen over cron implementations. As per usual, this
is implementation dependent and other software may suit your usecase better.

## Timers

Timers are useful for running things such as daily backups, alarms, and
any other automated system. Automation in general is useful because it removes
the human aspect of things, and timer programs such as cron, atd, and systemd
timer units can be incredibly useful for this.

An essential component to systemd that is often overlooked is it's ability to
replace `cron`, a timer tool that has a side effect of not running in a logind
session, and therefore can be used to escape resource restrictions and
permissions enforcements due to the way the daemon runs. This unfortunately is
something that happens with all daemons that are started outside of the
user's systemd session. Because cron is a system-level daemon, it's not started
in your session.

The Arch Wiki guide has a link [here][wiki-arch-systemd-timers] if you would
like a more formal introduction to systemd timers.

As an example, we can set a weekly timer to run a program in a binaries
directory:

```
# disco-party.timer
[Unit]
Description=Run our weekly disco-party program.

[Timer]
OnCalendar=weekly

[Install]
WantedBy=default.target

# disco-party.service
[Unit]
Description=Set up a Disco Party

[Service]
ExecStart=/home/%h/bin/disco-party
Type=oneshot
```

Since this is a user unit, you should use the default target (provided by
systemd when a session is ready).

The OnCalendar unit can take the values listed [here][systemd-realtime]. While
cron used a basic format, defining numbers in order of minute, hour, day,
month, and year, systemd instead has a different format:

```
OnCalendar=[weekday] <day of month>-<year>-<year> <hour>:<minute>:<second>
```

Any value can be replaced with a star (except for weekday I think, which can be
omitted in its entirety) to match "any" value, or a range can be provided. For example, to run a program on weekdays at 5 PM:

```
OnCalendar=Mon..Fri *-*-* 17:00:00
```

We can also set up a monotonic seconds-since timer, with various options such
as OnActiveSec (seconds since timer was started), OnBootSec (seconds since the
system booted), OnStartupSec (seconds since the *session* started, such as
when a user logs in for the first time since reboot), OnUnitActiveSec (seconds
since the unit was last activated), and OnUnitDeactiveSec (seconds since the
unit was last deactivated).

An example unit, ripped straight out of [shell-server][shell-server-ansible]:

```
# ansible-pull.timer
[Unit]
Description=Run ansible-pull every 15 mins

[Timer]
OnBootSec=15min
OnUnitDeactiveSec=15m

[Install]
WantedBy=timers.target
```

Since this is a system-level unit, you should use the timers.target unit,
provided by systemd when timers are ready to be run.

## Cron Run-Parts Imitation

Some `cron` implementations have a `@weekly`,`@daily`, and similar time options
which closely resemble the `OnCalendar=` option above. As such, we can
quickly produce something similar without using `cron`. This does require the
Debian `run-parts` command. [source][shell-server-cron]

```
# crontab.service
[Install]
WantedBy=multi-user.target

[Unit]
Description=Simulates cron, limited to /etc/cron.*
Requires=crontab@hourly.timer
Requires=crontab@daily.timer
Requires=crontab@weekly.timer
Requires=crontab@monthly.timer

# crontab@.service
[Unit]
Description=%I job for /etc/cron.%I
RefuseManualStart=yes
RefuseManualStop=yes
ConditionDirectoryNotEmpty=/etc/cron.%I

[Service]
Type=oneshot
IgnoreSIGPIPE=no
WorkingDirectory=/
ExecStart=/bin/run-parts --report /etc/cron.%I

# crontab@.timer
[Unit]
Description=%I timer simulating /etc/cron.%I
PartOf=crontab.target
RefuseManualStart=yes
RefuseManualStop=yes

[Timer]
OnCalendar=%I
Persistent=yes
```

This would need to be a system-level unit, which can be enabled by running the
command `sudo systemd enable --now crontab`. To avoid running in duplicate with
`cron` it is recommended to only do this if `cron` is **masked**, not just
disabled, as future updates can re-enable `cron`. You can do this by running
`sudo systemd mask cron`.

This article is a live post and will be updated if amendment is needed to
clarify explanations of certain topics.

EDIT-2020-08-15: Rewrite to be less snarky.

[wiki-arch-systemd-timers]: https://wiki.archlinux.org/index.php/Systemd/Timers
[systemd-realtime]: https://www.freedesktop.org/software/systemd/man/systemd.timer.html#OnCalendar=
[thoughts-on-npm]: {{< ref "2018-02-23-thoughts-on-npm.md" >}}
<!-- I have pinned the blob here as `master` may change the location of the lines in the future -->
[shell-server-ansible]: https://github.com/hashbang/shell-server/blob/d37bad8/ansible/tasks/hashbang/main.yml#L93-L101
[shell-server-cron]: https://github.com/hashbang/shell-server/blob/master/ansible/tasks/cron/main.yml
