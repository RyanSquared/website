+++
author = "Ryan Heywood"
title = "de1.hashbang.sh Incident Report - 2020-09-02"
date = "2020-09-02 16:44:15 -0500"
description = ""
tags = ["hashbang"]
featured = false
+++

**Note:** For convenience of the author, dates in  this post were made in
US/Central timezone.

At 3:25 AM today, the de1 hashbang server was unreachable and was not able to
connect to outside traffic. This was due to a lack of a reponse on our behalf
(for which I take partial blame for - I said I'd take care of it once I found
a suitable monitoring solution. I couldn't find one), and I don't blame
Hetzner for turning off our service. They said they would, and they did.  Below
is a timeline of events.

### August 30, 2020 - 1:40 AM (T-3days)

I recieved an email from Hetzner with an abuse report (which is not uncommon)
about a "NetscanOutLevel" from our server. This can happen if someone uses our
server as a proxy for netscanning.

### August 30, 2020 - 7:30 PM (T-2.5days, +5h)

I get a ping from daurnimator and go to actually investigate. I don't find
anything actively running a port monitor, but I do notice several proxies. I
take note that we don't have nmap installed.

I signal a retry and see that the issue no longer exists. I start looking for a
way to monitor outgoing port scans, in case this happens in the future.

### September 2, 2020 - 3:25 AM (T-0)

The server is disconnected. All outbound traffic is disabled... except for a
seemingly weird exception to irc.tilde.chat. I may have been connected to a
server in the same datacenter? I do not receive notice of the disconnect, as
I am asleep.

### September 2, 2020 - 8:45 AM (T+5hours20minutes)

I wake up, and check my phone. I see that I'm disconnected from IRC. I send an
email to Hetzner to see what it will take to get the server reconnected.

### September 2, 2020 - 10:28 AM (T+7hours, +1h40m)

I get a response from Hetzner, saying that I need to block server scans in the
[RFC1918] range. I begin work on this.

### September 2, 2020 - 2:08 PM (T+11hours40minutes, +4h40m)

After getting a German keyboard to US keyboard mapping, I spend several hours
looking into solutions for a permanent iptables record in our system, as I am
not able to log into the system without outbound networking enabled (as our
auth is hooked into userdb, an external service).

Eventually, I figure out that we're SUPPOSED TO BE using `ferm`. However, the
configuration for `ferm` had a [mistake], and `ferm` was [not enabled][1].

I was able to make the configurations manually through the VNC connection and
confirm with Hetzner that the issue was resolved. However, once the server
rebooted, the configuration was then replaced with the broken version.

I got the all-clear from Hetzner that our server should now be reconnected,
pushed the above two commits, and redeployed them manually on de1 (to have as
little downtime of `ferm` as possible).

[1]: https://github.com/hashbang/shell-server/commit/c8879eaa812eaa68b3da1b63e260fff8c8a335ad
[mistake]: https://github.com/hashbang/shell-server/commit/687eaa9cc25cf0c16da3f10d64b34d082916fa89
