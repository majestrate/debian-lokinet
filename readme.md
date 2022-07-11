# debian lokinet

:warning: builds of this may consume your first born child, use at your own risk :warning:

repo for building a debian iso with lokinet preinstalled.

## building

this guide is heavily based off [this blog post](https://willhaley.com/blog/custom-debian-live-environment/)

To build isos we need to install some packages, let's install them:

    $ sudo ./contrib/init.sh
    
Now we build the iso:

    $ sudo ./contrib/build.sh
    
After build the iso will be located in the root of the repo at `debian-lokinet.iso`

To generate a release torrent of the current build:

    $ ./contrib/release.sh


To install additional packages, add lines to `packages/99-custom.txt` containing the package name one per line or drop the deb into `packages/`


To clean up the workspace do:

    $ sudo ./contrib/clean.sh


## using

download the latest iso via bittorrent on the release page
