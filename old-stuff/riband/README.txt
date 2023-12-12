Riband: Ubuntu Driven Installation

* Introduction

Canonical has opted to provide different methods for installing and provisioning
Ubuntu Linux. The former "debian-installer" tool, from the Debian project, and
being used as the Ubuntu installer since Ubuntu creation, is being deprecated in
favor of a tool called "Subiquity" (or the "Ubiquity" for servers).

By the time this README.md file was finished, subiquity did not provide a
complete way to customize installation configuration options as
debian-installer, and debconf, does. For this reason, anyone that is willing to
customize and automate Ubuntu Server installations with the subiquity tool will
have to either:

Rely on its current "answers files" feature OR Have a full "curtin" setup
deployed to achieve similar (to d-i) results.

* Ubiquity (https://wiki.ubuntu.com/Ubiquity)

Ubiquity is a simple graphical live CD installer designed to integrate well with
Debian- and Ubuntu-based systems, written largely in Python, using d-i as a
backend for many of its functions for ease of maintenance.

* Subiquity (https://github.com/CanonicalLtd/subiquity/blob/master/DESIGN.md)

Ubiquity for Servers. Does not use d-i as its backend, use curtin instead.

Event driven loop approach with:

    MODEL
      Curtin (config files)
        subiquity.models
        subiquity.models.subiquity
        subiquity.models.network
        subiquity.models.keyboard

    VIEW
      Python urwid screens
      Each screen is managed by 1 instance of its controller class

    CONTROLLER
      1 instance of the controller CLASS per VIEW Connects:
              [world] <-> [model] <-> [view]

Note: Subiquity supports a limited form of automation in the form of an "answers
file". This yaml file provides data that controllers can use to drive the UI
automatically (this is not a replacement for pre-seeding: that is to be designed
during the 18.10 cycle). There are some answers files in the examples/ directory
that are run as a sort of integration test for the UI.

* Curtin (https://curtin.readthedocs.io/en/latest/)

Curtin is intended to be a bare bones “installer”. Its goal is to take data from
a source and get it onto disk as quick as possible and then boot it. The key
difference from traditional package-based installers is that curtin assumes the
thing its installing is intelligent and will do the right thing.

A usage of curtin will go through the following stages:

  - Install Environment boot
  - Early Commands
  - Partitioning
  - Network Discovery and Setup
  - Extraction of sources
  - Hook for installed OS to customize itself Final Commands

Note: Now, curtin doesn’t address how the system that it is running on is
booted. It could be booted from a live-cd or from a PXE boot environment. It
could even be booted off a disk in the system (although installation to that
disk would probably break things).

* Cloud-Init (https://cloudinit.readthedocs.io/en/latest/)

NEXT: (README-practice.txt || README-create-iso-test-vm.txt)