#!/bin/bash

HEALTH_PROBE_FILE="/tmp/kpf-health-probe.txt"
CONFIG_FILE="$(dirname "$0")/kpf-config.json"
FIRST_RUN="true"
EXPECTED_KEYS=( label local_port namespace protocol remote_port service )
BROWSER_WSL="explorer.exe"
BROWSER_MAC="Google Chrome"

check_for_config_file () {
  if [ ! -f "${CONFIG_FILE}" ]; then
    echo "Config file not found. Exiting."
    exit 1
  fi
}

load_config () {
  check_for_config_file

  JQ_KEYS=( $(cat ${CONFIG_FILE} | jq -r '. |= keys' | tr -d '[]",') )
  if [[ " ${JQ_KEYS[*]} " =~ " h " ]]; then 
    echo "'h' is a reserved key. Please replace the key in the config file. Aborting..."
    exit 1
  fi
  options=":h$(echo ${JQ_KEYS[@]} | tr -d ' ')"
  for jq_key in ${JQ_KEYS[@]}; do
    RETURNED_KEYS=( $(cat ${CONFIG_FILE} | jq ".${jq_key}" | jq keys | tr -d '[]",') )
    if [[ "${RETURNED_KEYS[@]}" != "${EXPECTED_KEYS[@]}" ]]; then
      echo "Config file is invalid. Exiting."
      exit 1
    fi
  done
}

load_config

usage="./$(basename "$0") [-option]
Heaven for kubectl port forward :)
options:
    -h  help"

for jq_key in ${JQ_KEYS[@]}; do
  label=$(cat ${CONFIG_FILE} | jq -r ".${jq_key}.label")
  usage="${usage}
    -${jq_key}  ${label}"
done

CASE_OPTIONS="$(echo ${JQ_KEYS[@]} | tr ' ' '|')"
eval "
while getopts \"\$options\" option; do
  case \"\$option\" in
    $CASE_OPTIONS) KEY=\"\$option\" ;;
    *) echo \"\$usage\"; exit;;
  esac
done
"

if [[ ${OPTIND} -eq 1 ]]; then
  echo "No flags were used. Aborting..."
  echo ""
  echo "Usage: ${usage}"
  exit 1
fi

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

  echo "Establishing port forward connection to ${SERVICE} -n ${NAMESPACE}..."
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
      open -a "${BROWSER_MAC}" "${PROTOCOL}://localhost:${PORT}"
    elif [[ "${OS}" == "Linux" ]]; then #WSL
      ${BROWSER_WSL} "${PROTOCOL}://localhost:${PORT}"
    fi
    FIRST_RUN="false"
  fi
}

trigger () {
  echo "${HEALTH_PROBE_FILE} is changed."
  kill -9 ${BG_PROCESS_ID}
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

check_os
check_dependencies
establish_port_forward_connection
