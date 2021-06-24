# debian lokinet

repo for building a debian iso with lokinet preinstalled.

## building

this guide is heavily based off [this blog post](https://willhaley.com/blog/custom-debian-live-environment/)

To build isos we need to install some packages, let's install them:

    $ sudo ./contrib/init.sh
    
Now we build the iso:

    $ sudo ./contrib/build.sh
    
After build the iso will be located in the root of the repo at `debian-lokinet.iso`


To install additional packages, add lines to `packages/custom.txt` containing the package name one per line or drop the deb into `packages/`


To clean up the workspace do:

    $ sudo ./contrib/clean.sh

