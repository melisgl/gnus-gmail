Gmail via Local IMAP with Gnus
================================

Remote IMAP can be slow. With [Gnus][gnus], it definitely is. So,
people typically sync Gmail to a local IMAP server and connect Gnus to
that.

This guide and config takes inspiration from [dickmao's][dickmao]. I
assume that:

- Filters that assign labels are set up on Gmail. That is, we have
  server-side [mail splitting][mail-splitting].
- We have a Debian-based system with [systemd][systemd].

Compared to dickmao's, the main contributions are:

- Low-latency mail delivery
- Proper handling of suspend-resume
- Sane deletion semantics: deleting an email moves it to Trash in Gmail
- Gnus config for server-side spam filtering


## Overview

We use [goimapnotify][] on Gmail IMAP to wait for new mail, trigger an
[mbsync][] and tell Gnus get new news via [Emacs
server][emacs-server].


## Installation


### Gmail Settings

Go to the Gmail IMAP settings:

https://mail.google.com/mail/u/0/#settings/fwdandpop

Alternatively, go to your Gmail inbox, click on the gear icon, on `See
all settings`, then on `Forwarding and POP/IMAP`.

Here, disable `auto-expunge` in the Gmail IMAP settings and set `When
a message is marked as deleted and expunged from the last visible IMAP
folder:` to `Move the message the Trash`. If `auto-expunge` were
enabled, deleting an email from an IMAP folder would cause Gmail to
remove the corresponding label and archive the message but not delete
it.

Now go to https://mail.google.com/mail/u/0/#settings/labels (the
`Labels` tab), and ensure that the `Show in IMAP` box is checked for
`All Mails`. Check this box for other labels you want see as IMAP
folders.


### Installing dependencies

As root:

    apt install golang isync dovecot

As the normal user:

    go install gitlab.com/shackra/goimapnotify/cmd/goimapnotify@latest

I assume you have gpg and Emacs set up.


### Install the Files

Check what will be installed:

    ls -lAR ./files/

Copy the files and ensure the Maildir (`~/.mail` by default) exists:

    ./install.sh <MAILDIR>


### Authentication

Create an [app password](google-app-password) to access Gmail.

#### IMAP

Create `gmail-username` and `gmail-password.gpg` in the above
`<MAILDIR>` with the only email address (e.g. `xxx@gmail.com`) and the
app password in them (no spaces, no newline at the end either).

#### SMTP

For smtpmail in Emacs, ensure that `~/.authinfo.gpg` or `~/.authinfo`
provides the credentials to access the SMTP ports on Gmail:

    machine smtp.gmail.com login <USERNAME>@gmail.com password <APP-PASSWD> port 465

Port 465 is for implicit TLS (`smtpmail-stream-type` `ssl`) You would
use port 587 for STARTTLS (`smtpmail-stream-type` `starttls`).


### Gnus Setup

See [`gnus-minimal.el`](gnus-minimal.el) for an example Gnus setup that
works with this setup. This is not installed by `install.sh`. Copy it
verbatim or in parts.


## Behind the Scenes

If all goes well, you don't need to read this section. Comments in the
configuration files provide additional information on the design
choices.


### Goimapnotify Setup

See [`goimapnotify.yaml`](files/.config/goimapnotify/goimapnotify.yaml)

You can test that things work by running `~/go/bin/goimapnotify`.


### Mbsync Setup

See [`.mbsyncrc`](files/.mbsyncrc) and
[`mbsync-gmail-full`](files/bin/mbsync-gmail-full).

You can test that things work by running `~/bin/mbsync-gmail-full`.
This runs mbsync and tells Gnus to check for new mail via [Emacs
server][emacs-server].

Note that the initial sync can take a long time and may trigger Gmail
throttling. Look for `THROTTLED` in the output of `mbsync -V -DmMnN --all`.


### Systemd Setup

See the [systemd config files](files/.config/systemd/user/).

- `goimapnotify.service` keeps `goimapnotify` running.
- `monitor-resume.timer` restarts `goimapnotify.service` when the
  system resumes from e.g suspend.
- `mbsync.timer` runs a full mbsync every hour to propagate local
  changes (e.g. deletes, moves, read status) to Gmail.

You can monitor their outputs with

    journalctl --user -u mbsync.service -u mbsync.timer \
        -u goimapnotify.service -u monitor-resume.service -f


  [gnus]: https://www.gnu.org/software/emacs/manual/html_node/gnus/index.html#Top
  [dickmao]: https://github.com/dickmao/gnus-imap-walkthrough
  [mail-splitting]: https://www.gnu.org/software/emacs/manual/html_node/gnus/Splitting-Mail.html
  [systemd]: https://systemd.io/
  [google-app-password]: https://support.google.com/accounts/answer/185833
  [goimapnotify]: https://gitlab.com/shackra/goimapnotify
  [mbsync]: https://isync.sourceforge.io/
  [emacs-server]: https://www.gnu.org/software/emacs/manual/html_node/emacs/Emacs-Server.html
