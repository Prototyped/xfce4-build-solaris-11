# Build script for XFCE 4.20.0 for Solaris 11

This project contains a script and supporting patch to build the components
comprising XFCE 4.20.0 for Solaris 11. This has been tested with Solaris
11.4.81 for i86 PC. It has not been tested with SPARC hosts at all.

The script

- installs dependencies of XFCE itself as well as build tools
- downloads and unpacks the XFCE 4.20.0 sources and separately checks out
  sources for support components from git repositories
- builds and installs XFCE and support components in the correct order

## Branch `archive-builder`

The branch `archive-builder` has a version of the script that, instead of
installing XFCE and support components to `/usr/local`, installs them to
`build/xfce-solaris11-4.20.0` and archives them to
`build/xfce-solaris11-4.20.0.tar.bz2`. The binaries are built without
rpath so they can be relocated on disk.
