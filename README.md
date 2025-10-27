# Build script for XFCE 4.20.0 for Solaris 11

This project contains a script and supporting patch to build the components
comprising XFCE 4.20.0 for Solaris 11. This has been tested with Solaris
11.4.81 for i86 PC. It has not been tested with SPARC hosts at all.

The script

- installs dependencies of XFCE itself as well as build tools
- downloads and unpacks the XFCE 4.20.0 sources and separately checks out
  sources for support components from git repositories
- builds and installs XFCE and support components in the correct order
