# wshterm

`wshterm` is a terminal emulator for the browser.

`wshterm` combines hterm with a backend application to provide a terminal
emulator for the browser. Communication is done via websockets.

## Features

* Runs most CLI and TUI programs (haven't found one that didn't work yet)
* Ability to display images using the iTerm inline image escape sequences
* Supports resizing the terminal
* Run an arbitary command on connection.

It currently does not support SSL, it is currently expected that if you
need SSL, you will put it behind a reverse proxy such as NGINX.

It currently does not drop priveleges. Don't run it as `root`. Use the
provided `ssh_local` script if you want to authenticate.

## Usage

Simply run as the user you want to run as, and specify a command to be
executed.

    # Run a GHCi session on port 8080
    wshterm -p 8080 ghci

    # Allow logging in as any user
    sudo -u nobody wshterm ./ssh_local
