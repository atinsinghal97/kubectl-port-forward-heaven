#!/bin/bash

HEALTH_PROBE_FILE="/tmp/kpf-health-probe.txt"
CONFIG_FILE="/Users/atinsinghal97/Github/kubectl-port-forward-heaven/kpf-config.json"
FIRST_RUN="true"
KEY=""
OS=""
BG_PROCESS_ID=""

usage="./$(basename "$0") [-h] [-c] [-s] [-w]
Heaven for kubectl port forward :)
where:
    -h  help
    -c  argocd
    -s  stackrox
    -w  argo-workflows-server"

check_os () {
  OS_CODE="$(uname -s)"
  case "${OS_CODE}" in
      Linux*)     OS=Linux;;
      Darwin*)    OS=Mac;;
      *)          echo "Unknown OS: ${OS_CODE}"; exit 1;;
  esac
}

check_dependencies () {
  if [[ "${OS}" == "Mac" ]]; then
    DEPENDENCY_STATUS="command -v fswatch"
  elif [[ "${OS}" == "Linux" ]]; then
    DEPENDENCY_STATUS="command -v inotifywait"
  fi

  if [[ -z DEPENDENCY_STATUS ]]; then
    echo "Dependency not found. Please install fswatch (mac) or inotifywait (WSL)."
    exit 1
  fi
}

establish_port_forward_connection () {
  NAMESPACE=$(jq -r ".${KEY}.namespace" "${CONFIG_FILE}")
  SERVICE=$(jq -r ".${KEY}.service" "${CONFIG_FILE}")
  LOCAL_PORT=$(jq -r ".${KEY}.local_port" "${CONFIG_FILE}")
  REMOTE_PORT=$(jq -r ".${KEY}.remote_port" "${CONFIG_FILE}")
  PROTOCOL=$(jq -r ".${KEY}.protocol" "${CONFIG_FILE}")

  kubectl port-forward -n "${NAMESPACE}" "${SERVICE}" "${LOCAL_PORT}":"${REMOTE_PORT}" 2> "${HEALTH_PROBE_FILE}" 1> /dev/null &
  BG_PROCESS_ID=$!
  open_browser "${PROTOCOL}" "${LOCAL_PORT}"
  monitor
}

open_browser () {
  PROTOCOL="${1}"
  PORT="${2}"
  if [[ "${FIRST_RUN}" == "true" ]]; then
    if [[ "${OS}" == "Mac" ]]; then
      open -a "Google Chrome" "${PROTOCOL}://localhost:${PORT}"
    elif [[ "${OS}" == "Linux" ]]; then #WSL
      explorer.exe "${PROTOCOL}://localhost:${PORT}"
    fi
    FIRST_RUN="false"
  fi
}

trigger () {
  echo "${HEALTH_PROBE_FILE} is changed."
  # kill -9 ${BG_PROCESS_ID}
  establish_port_forward_connection 
}

monitor () {
  if [[ "${OS}" == "Mac" ]]; then
    fswatch ${HEALTH_PROBE_FILE} -1 | while read; do trigger; done
  elif [[ "${OS}" == "Linux" ]]; then
    while inotifywait -q -e modify ${HEALTH_PROBE_FILE} >/dev/null; do
      trigger
    done
  fi
}

options=':hcsw'
while getopts $options option; do
  case "${option}" in
    c) KEY="${option}" ;;
    s) KEY="${option}" ;;
    w) KEY="${option}" ;;
    *) echo "${usage}"; exit;;
  esac
done

if [ ${OPTIND} -eq 1 ]; then echo "No options were passed"; echo ""; echo "Usage: ${usage}"; fi

check_os
check_dependencies
establish_port_forward_connection