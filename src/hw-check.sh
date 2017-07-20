#!/bin/bash

# hw-check - Hardware health check and alerting
# Copyright (C) 2017 Francis Chin <dev@fchin.com>
#
# Repository: https://github.com/chinf/hw-check
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published
# by the Free Software Foundation, either version 3 of the License, or (at
# your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser
# General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

log() { # level, message
  local LEVEL=$1
  shift 1
  case $LEVEL in
    (inf*) if [ -z "${WARNONLY}" ]; then REPORT+="$*\n"; fi ;;
    (war*) REPORT+="hw-check warning: $*\n" ;;
    *)
      REPORT+="hw-check error: $*\n"
      echo "hw-check error: $*" >&2
      ;;
  esac
}

output_report() { # [email subject]
  if [ "${EMAIL}" ]; then
    echo -e "${REPORT}" | mail -r "hw-check@`uname -n`" \
      -s "hw-check on `uname -n`: $*" "${EMAIL}"
  else
    echo -e "${REPORT}" >&1
  fi
}

#
# Options
#
EDACLOG=/var/log/kern.log
CHECKLIST="edac sensors"
print_usage() {
  echo "Usage: $0 [options]
Hardware health check and alerting.

  -c CHECK     CHECK is one of 'edac', 'sensors'.  All checks are
               run by default unless this option is specified.
               Repeat this option to specify more than one check.

  -m ADDRESS   Email report (if not empty) to ADDRESS instead of
               sending to STDOUT.  Repeat to specify multiple email
               addresses.

  -w           Report only warnings or errors.
" >&2
exit 2
}

while getopts ":c:m:w" OPT; do
  case "${OPT}" in
    c)
      VALIDCHECK=
      for CHECK in $CHECKLIST; do
        if [ "${OPTARG}" = "${CHECK}" ]; then
          VALIDCHECK="${OPTARG}"
          break
        fi
      done
      if [ "${VALIDCHECK}" ]; then
        CHECKS+="${VALIDCHECK} "
      else
        print_usage
      fi
      ;;
    m)
      if [ "${OPTARG}" ]; then
        EMAIL+="${OPTARG} "
      else
        print_usage
      fi
      ;;
    w) WARNONLY=yes ;;
    *) print_usage ;;
  esac
done

if [ -z "${CHECKS}" ]; then CHECKS=$CHECKLIST; fi


#
# Check functions
#
edac_check() {
  EDACSTATUS="`edac-util -s 2>&1`"
  case $? in
    0) log info "${EDACSTATUS}" ;;
    1) 
      log error "No EDAC driver module loaded:\n${EDACSTATUS}"
      log error "Refer to documentation and check /etc/modules."
      SUBJECT+="[EDAC drivers]"
      return 3
      ;;
    *)
      # edac-utils package may not be installed, or other error
      # with executing edac-util command
      log error "${EDACSTATUS}"
      log error "Check that package 'edac-utils' is installed."
      SUBJECT+="[edac-utils]"
      return 3
      ;;
  esac

  # Read current EDAC error report
  EDACERRORS=`edac-util -q`
  if [ "${EDACERRORS}" ]; then
    log warn `edac-util -v`
    SUBJECT+="[hardware errors]"
  else
    log info "No hardware errors reported from edac-util"
  fi

  # Check logs for recent hardware errors
  LOGERRORS=$(env LC_ALL=C sudo cat "${EDACLOG}" \
  | grep -e "\[Hardware Error\]")
  if [ "${LOGERRORS}" ]; then
    log warn "${LOGERRORS}"
    SUBJECT+="[logged hardware errors]"
  else
    log info "No hardware errors reported in ${EDACLOG}"
  fi
}

sensors_check() {
  SENSORSSTATUS=`sensors`
  if [ $? -ne 0 ]; then
    log error "${SENSORSSTATUS}"
    SUBJECT+="[lm-sensors]"
    return 3
  fi

  # Check for any alarms
  SENSORSERRORS=$(env LC_ALL=C echo "${SENSORSSTATUS}" | grep "ALARM")
  if [ "${SENSORSERRORS}" ]; then
    log warn "sensors alarms:\n${SENSORSERRORS}"
    SUBJECT+="[sensors alarms]"
  else
    log info "No sensor alarms reported from lm-sensors"
  fi
}

#
# main()
#
log info "hw-check started: `date`"

for CHECK in $CHECKS; do
  case $CHECK in
    edac) edac_check ;;
    sensors) sensors_check ;;
    *) log error "${CHECK} check not implemented" ;;
  esac
done

# End hw-check
log info "\nhw-check finished: `date`"
if [ "${REPORT}" ]; then
  output_report "${SUBJECT}"
fi
