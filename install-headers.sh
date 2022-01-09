#!/bin/bash
# Copyright (C) 2021, FreeLancer Development Team
# All right's reserved...
#
# Routines for BlackHole OS source maintainance.

scriptpath="$(dirname $(realpath $0))"
. "$scriptpath/common.sh"

info "Copying headers to their corresponding directories."
