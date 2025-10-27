#!/usr/bin/env bash

set -euxo pipefail

cleanup_build() {
    rm -rf build
}

install_dependency_packages() {
    pkg install curl gnu-coreutils gnu-findutils gnu-binutils gcc gnu-make \
        pkg-config glib2 atk pixman pango cairo gtk3 intltool \
        startup-notification dbus pkg://solaris/developer/gnome/gettext \
        x11/library/\* pbzip2 gdk-pixbuf gobject-introspection autoconf \
        automake git gnu-sed cmake meson wget libwnck3 gstreamer-1 \
        gst-plugins-base gst-plugins-good libgsf poppler-viewer libnotify \
        colord polkit adwaita-icon-theme os-backgrounds os-backgrounds-extra \
        gnome-themes-standard hicolor-icon-theme xcursor-themes || {
        exit_status="$?"
        if [[ "$exit_status" -ne 4 ]]
        then
            exit "$exit_status"
            # else "nothing to do."
        fi
    }
}

pull_sources() {
    mkdir -p build
    cd build
    curl -fLSso xfce-4.20.tar.bz2 \
         https://archive.xfce.org/xfce/4.20/fat_tarballs/xfce-4.20.tar.bz2
    gtar -I pbzip2 -xSpf xfce-4.20.tar.bz2
    cd src
    for f in *.tar.bz2
    do
        gtar -I pbzip2 -xSpf "$f"
    done
    git clone https://gitlab.freedesktop.org/emersion/libdisplay-info.git \
        -b 0.3.0
    git clone https://github.com/vcrhonek/hwdata.git -b v0.400
}

build_libdisplay_info() {
    cd build/src/libdisplay-info
    gsed -ri '/^[[:space:]]{1,}link_args:/d; /^[[:space:]]{1,}link_depends:/d' \
         meson.build
    meson setup build/
    ninja -C build/
    ninja -C build/ install
}

build_hwdata() {
    cd build/src/hwdata
    ./configure
    gsed -ri 's/^([[:space:]]{1,})install/\1ginstall/; s/\<sed\>/gsed/' \
         Makefile
    gsed -ri 's/\xb4/\xb3/' 01-utf-8-encoding.patch.patch
    gmake download
    gmake install
}

run_configure() {
    env GDBUS_CODEGEN=/usr/bin/gdbus-codegen \
        GLIB_COMPILE_RESOURCES=/usr/bin/glib-compile-resources \
        GLIB_GENMARSHAL=/usr/bin/glib-genmarshal \
        GLIB_COMPILE_SCHEMAS=/usr/bin/glib-compile-schemas \
        GLIB_GETTEXTIZE=/usr/bin/glib-gettextize \
        GLIB_MKENUMS=/usr/bin/glib-mkenums \
        GOBJECT_QUERY=/usr/bin/gobject-query \
        GSETTINGS=/usr/bin/gsettings \
        GIO_QUERYMODULES=/usr/bin/gio-querymodules \
        MAKE=gmake \
        ./configure --disable-debug "$@" # --disable-silent-rules
}

fix_msgfmt_in_makefiles() {
    find . -type f -name Makefile -print0 |
        gxargs -0 gsed -ir '
            s/^MSGFMT = :$/MSGFMT = $(GMSGFMT)/g;
            s/^MSGFMT_015 = :$/MSGFMT_015 = $(GMSGFMT_015)/g;
            s/^MSGFMT_ = :$/MSGFMT_ = $(GMSGFMT_)/g;
            s/^MSGFMT_yes = :$/MSGFMT_yes = $(GMSGFMT_yes)/g;
            s/^MSGFMT_no = :$/MSGFMT_no = $(GMSGFMT_no)/g'
}

build_xfce_package() {
    local package_name="$1"
    shift
    cd build/src/${package_name}-4.20.0
    run_configure "$@"
    gmake -j$(nproc)
    fix_msgfmt_in_makefiles
    gmake install
}

build_xfce4_power_manager() {
    cd build/src/xfce4-power-manager-4.20.0
    gpatch -p0 < ../../../xfce4-power-manager-4.20.0.patch
    run_configure --disable-wayland --enable-x11 --enable-xfce4panel
    gsed -ri 's/^\/\* #undef BACKEND_TYPE_OPENBSD \*\/$/#define BACKEND_TYPE_SOLARIS 1/' \
         config.h
    gmake -j$(nproc)
    fix_msgfmt_in_makefiles
    gmake install
}

main() {
    (install_dependency_packages)
    (cleanup_build)
    (pull_sources)
    PKG_CONFIG_PATH=/usr/lib/64/pkgconfig:/usr/local/lib/64/pkgconfig:/usr/local/lib/pkgconfig
    export PKG_CONFIG_PATH
    (build_libdisplay_info)
    (build_hwdata)
    (build_xfce_package xfce4-dev-tools)
    (build_xfce_package libxfce4util)
    (build_xfce_package libxfce4ui)
    (build_xfce_package garcon)
    (build_xfce_package exo)
    (build_xfce_package thunar --enable-gio-unix --enable-exif --enable-pcre2 \
                        --with-x)
    (build_xfce_package libxfce4windowing --disable-wayland --enable-x11)
    (build_xfce_package tumbler)
    (build_xfce_package xfce4-appfinder)
    (build_xfce_package xfce4-panel --disable-wayland --enable-x11)
    (build_xfce4_power_manager)
    (build_xfce_package xfce4-settings --enable-gio-unix --enable-colord \
                        --enable-upower-glib --enable-libnotify \
                        --enable-xorg-libinput --enable-xcursor --enable-xrandr
    )
    (build_xfce_package xfdesktop --disable-wayland --enable-x11 \
                        --enable-notifications --enable-desktop-menu \
                        --enable-thunarx --enable-file-icons)
    (build_xfce_package xfwm4 --disable-wayland --enable-x11 --enable-poswin \
                        --enable-compositor --enable-xpresent --enable-randr \
                        --enable-render --enable-xsync --enable-epoxy \
                        --enable-startup-notification --enable-xi2)
    (build_xfce_package xfce4-session --disable-wayland --enable-x11 \
                        --enable-polkit)
}

main
