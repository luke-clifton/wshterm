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

