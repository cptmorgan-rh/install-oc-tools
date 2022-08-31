#!/usr/bin/env bash

set -e

OS=$(uname -s)

if [ "${OS}" == 'Linux' ]; then
  OS=linux
  OCTOOLSRC="$(getent passwd "$SUDO_USER" | cut -d: -f6)"/.octoolsrc
elif [ "${OS}" == 'Darwin' ]; then
  OS=mac
  OCTOOLSRC="${HOME}"/.octoolsrc
else
  echo "OS Unsupported: ${OS}"
  exit 99
fi

MIRROR_DOMAIN='https://mirror.openshift.com'
USEROVERRIDE=false

if [ -z ${ARCH} ]; then
  ARCH=$(uname -m)
  if [ "${ARCH}" == 'x86_64' ]; then
    MIRROR_PATH='/pub/openshift-v4/x86_64/clients'
  elif [ "${ARCH}" == 'arm64' ]; then
    MIRROR_PATH='/pub/openshift-v4/arm64/clients'
  elif [ "${ARCH}" == 's390x' ]; then
    MIRROR_PATH='/pub/openshift-v4/s390x/clients'
  elif [ "${ARCH}" == 'ppc64le' ]; then
    MIRROR_PATH='/pub/openshift-v4/ppc64le/clients'
  else
    echo "Architecture Unsupported: ${ARCH}"
    exit 99
  fi
else
  if [ "${ARCH}" == 'x86_64' ]; then
    MIRROR_PATH='/pub/openshift-v4/x86_64/clients'
  elif [ "${ARCH}" == 'arm64' ]; then
    MIRROR_PATH='/pub/openshift-v4/arm64/clients'
  elif [ "${ARCH}" == 's390x' ]; then
    MIRROR_PATH='/pub/openshift-v4/s390x/clients'
  elif [ "${ARCH}" == 'ppc64le' ]; then
    MIRROR_PATH='/pub/openshift-v4/ppc64le/clients'
  else
    echo "Architecture Unsupported: ${ARCH}"
    echo "Supported Architectures: x86_64 arm64 s390x ppc64le"
    exit 99
  fi
fi

BIN_PATH="/usr/local/bin"

setup() {

  # Allow user overrides
  if [ -f "${OCTOOLSRC}" ]; then
    echo ".octoolsrc file detected, overriding defaults..."
    source "${OCTOOLSRC}"
    USEROVERRIDE=true
    if [ ! -d "${BIN_PATH}" ]; then
      echo -e "\n${BIN_PATH} does not exist."
      exit 1
    fi
  fi

}

run() {

  case "$1" in
    --latest)
      release "$2" "latest"
      ;;
    --stable)
      release "$2" "stable"
      ;;
    --fast)
      release "$2" "fast"
      ;;
    --candidate)
      release "$2" "candidate"
      ;;
    --nightly)
      nightly "$2"
      ;;
    --version)
      version "$2"
      ;;
    --info)
      version_info "$2"
      ;;
    --cleanup)
      remove_old_ver
      ;;
    --help)
      show_help
      exit 0
      ;;
    --update)
      latest
      ;;
    --cli)
      cli "$2"
      ;;
    --uninstall)
      uninstall
      ;;
    *)
      show_help
      exit 0
  esac

}

check_root(){

  if [ "${USEROVERRIDE}" != "true" ] && [ "$EUID" -ne 0 ];
  then
      echo "This command requires root access to run."
      exit 1
  fi

}

check_prereq(){

#Check for wget
if [ ! $(command -v wget) ]; then
  echo "wget not found. Please install wget."
  exit 1
fi

status_code=$(curl --write-out "%{http_code}" --silent --output /dev/null "${MIRROR_DOMAIN}${MIRROR_PATH}/ocp/stable/release.txt")

if [[ "$status_code" -ne 200 ]]; then
  echo "Internet Access is required for this tool to run."
  exit 1
fi

}

restore(){

  if [[ "$1" == "" ]]; then
    VERSION=$(curl -s "${MIRROR_DOMAIN}${MIRROR_PATH}/ocp/$2/release.txt"    | grep 'Name:' | awk '{ print $NF }')
  else
    VERSION=$(curl -s "${MIRROR_DOMAIN}${MIRROR_PATH}/ocp/$2-$1/release.txt" | grep 'Name:' | awk '{ print $NF }')
  fi

  if ls "${BIN_PATH}/oc.${VERSION}.bak" 1> /dev/null 2>&1 && ls "${BIN_PATH}/openshift-install.${VERSION}.bak" 1> /dev/null 2>&1 && ls "${BIN_PATH}/kubectl.${VERSION}.bak" 1> /dev/null 2>&1
  then
    read -rp "Found backup of version ${VERSION}. Restore?
    $(echo -e "\nY/N? ")"
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      backup restore
      for i in openshift-install oc kubectl; do mv "${BIN_PATH}/${i}.${VERSION}.bak" "${BIN_PATH}/${i}"; done
      show_ver
      exit 0
    elif [[ $REPLY =~ ^[Nn]$ ]]; then
      echo "Downloading files..."
    fi
  fi

}

restore_version(){

  if ls "${BIN_PATH}/oc.${1}.bak" 1> /dev/null 2>&1 && ls "${BIN_PATH}/openshift-install.${1}.bak" 1> /dev/null 2>&1 && ls "${BIN_PATH}/kubectl.${1}.bak" 1> /dev/null 2>&1
  then
    read -rp "Found backup of version $1. Restore?
    $(echo -e "\nY/N? ")"
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      backup restore
      for i in openshift-install oc kubectl; do mv "${BIN_PATH}/${i}.${1}.bak" "${BIN_PATH}/${i}"; done
      show_ver
      exit 0
    elif [[ $REPLY =~ ^[Nn]$ ]]; then
      echo "Downloading files..."
    fi
  fi

}

verify_version(){

status_code=$(curl --write-out "%{http_code}" --silent --output /dev/null "$1")

if [[ "$status_code" -ne 200 ]]; then
  echo "Version $2 does not exist"
  exit 1
fi

}

version_info(){

  if [[ $1 =~ ^4+\.[0-9]+\.[0-9]+$ ]]; then
    status_code=$(curl --write-out "%{http_code}" --silent --output /dev/null "${MIRROR_DOMAIN}${MIRROR_PATH}/ocp/$1/release.txt")
    releasetext="${MIRROR_DOMAIN}${MIRROR_PATH}/ocp/$1/release.txt"
  else
    status_code=$(curl --write-out "%{http_code}" --silent --output /dev/null "${MIRROR_DOMAIN}${MIRROR_PATH}/ocp/latest-$1/release.txt")
    releasetext="${MIRROR_DOMAIN}${MIRROR_PATH}/ocp/latest-$1/release.txt"
  fi

  if [[ "$status_code" -ne 200 ]]; then
    echo "Version $1 does not exist"
    exit 1
  else
    ver_name=$(curl --silent "${releasetext}" 2>/dev/null | grep Name | sed -e 's/Name:      //' | sed -e 's/^[ \t]*//')
    created_date=$(curl --silent "${releasetext}" 2>/dev/null | grep Created | sed -e 's/Created:   //' | sed -e 's/^[ \t]*//')
    errata_url=$(curl --silent "${releasetext}" 2>/dev/null | grep url | sed -e 's/    url: //')
    k8s_ver=$(curl --silent "${releasetext}" 2>/dev/null | grep -m1 kubernetes | sed -e 's/kubernetes //' | sed -e 's/^[ \t]*//')
    upgrades=$(curl --silent "${releasetext}" 2>/dev/null | grep Upgrades | sed -e 's/  Upgrades: //')
    rhcos_ver=$(curl --silent "${releasetext}" 2>/dev/null | grep machine-os -m1 | sed -e 's/  machine-os //' | sed -e 's/ Red Hat Enterprise Linux CoreOS//')

    echo "$ver_name Version Info:"
    echo -e "\nCreated Date: $created_date"
    echo -e "\nKubernetes Version: $k8s_ver"
    echo -e "\nRHCOS Version: $rhcos_ver"
    echo -e "\n$ver_name can be upgraded from the following versions:"
    echo -e "\n$upgrades"
    echo -e "\nErrata: $errata_url"
    echo -e "\nRelease File: $releasetext"
    echo -e "\n"
    exit 0
  fi

}

version() {

  check_root

  restore_version "$1"

  if [[ "$1" == "" ]]; then
    echo "Please specify a version."
    echo "Example: install-oc-tools --version 4.4.10"
    exit 1
  fi

  status_code=$(curl --write-out "%{http_code}" --silent --output /dev/null "${MIRROR_DOMAIN}${MIRROR_PATH}/ocp/$1/release.txt")

  if [[ "$status_code" -ne 200 ]]; then
    echo "Version $1 does not exist"
    exit 1
  else
    VERSION=$(curl -s "${MIRROR_DOMAIN}${MIRROR_PATH}/ocp/$1/release.txt" | grep 'Name:' | awk '{ print $NF }')
    CUR_VERSION=$(oc version 2>/dev/null | grep Client | sed -e 's/Client Version: //')
    if [ "$VERSION" == "$CUR_VERSION" ]; then
      echo "${VERSION} already installed."
      exit 0
    fi
    CLIENT="${MIRROR_DOMAIN}${MIRROR_PATH}/ocp/$1/openshift-client-${OS}.tar.gz"
    INSTALL="${MIRROR_DOMAIN}${MIRROR_PATH}/ocp/$1/openshift-install-${OS}.tar.gz"
    download "$CLIENT" "$INSTALL"
  fi

}

release() {

  check_root

  restore "$1" "$2"

  if [[ $1 =~ ^4+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Specific version specified. Downloading that version."
    printf "\n"
    version $1
  fi

  if [[ "$1" == "" ]]; then
    VERSION=$(curl -s "${MIRROR_DOMAIN}${MIRROR_PATH}/ocp/$2/release.txt" | grep 'Name:' | awk '{ print $NF }')
    CUR_VERSION=$(oc version 2>/dev/null | grep Client | sed -e 's/Client Version: //')
      if [ "$VERSION" == "$CUR_VERSION" ]; then
        echo "${VERSION} is installed."
        exit 0
      fi
    CLIENT="${MIRROR_DOMAIN}${MIRROR_PATH}/ocp/$2/openshift-client-${OS}.tar.gz"
    INSTALL="${MIRROR_DOMAIN}${MIRROR_PATH}/ocp/$2/openshift-install-${OS}.tar.gz"
    download "$CLIENT" "$INSTALL"
  else
    verify_version "${MIRROR_DOMAIN}${MIRROR_PATH}/ocp/$2-$1/release.txt" "$1"
    VERSION=$(curl -s "${MIRROR_DOMAIN}${MIRROR_PATH}/ocp/$2-$1/release.txt" | grep 'Name:' | awk '{ print $NF }')
    CUR_VERSION=$(oc version 2>/dev/null | grep Client | sed -e 's/Client Version: //')
    if [ "$VERSION" == "$CUR_VERSION" ]; then
      echo "${VERSION} already installed."
      exit 0
    fi
    CLIENT="${MIRROR_DOMAIN}${MIRROR_PATH}/ocp/$2-$1/openshift-client-${OS}.tar.gz"
    INSTALL="${MIRROR_DOMAIN}${MIRROR_PATH}/ocp/$2-$1/openshift-install-${OS}.tar.gz"
    download "$CLIENT" "$INSTALL"
  fi

}

nightly() {

  check_root

  if [[ "$1" == "" ]]; then
    VERSION=$(curl -s "${MIRROR_DOMAIN}${MIRROR_PATH}/ocp-dev-preview/latest/release.txt" | grep 'Name:' | awk '{ print $NF }')
    CUR_VERSION=$(oc version 2>/dev/null | grep Client | sed -e 's/Client Version: //')
      if [ "$VERSION" == "$CUR_VERSION" ]; then
        echo "${VERSION} is installed."
        exit 0
      fi
    CLIENT="${MIRROR_DOMAIN}${MIRROR_PATH}/ocp-dev-preview/latest/openshift-client-${OS}.tar.gz"
    INSTALL="${MIRROR_DOMAIN}${MIRROR_PATH}/ocp-dev-preview/latest/openshift-install-${OS}.tar.gz"
    download "$CLIENT" "$INSTALL"
  else
    verify_version "${MIRROR_DOMAIN}${MIRROR_PATH}/ocp-dev-preview/latest-$1/release.txt" "$1"
    VERSION=$(curl -s "${MIRROR_DOMAIN}${MIRROR_PATH}/ocp-dev-preview/latest-$1/release.txt" | grep 'Name:' | awk '{ print $NF }')
    CUR_VERSION=$(oc version 2>/dev/null | grep Client | sed -e 's/Client Version: //')
    if [ "$VERSION" == "$CUR_VERSION" ]; then
      echo "$VERSION already installed."
      exit 0
    fi
    CLIENT="${MIRROR_DOMAIN}${MIRROR_PATH}/ocp-dev-preview/latest-$1/openshift-client-${OS}.tar.gz"
    INSTALL="${MIRROR_DOMAIN}${MIRROR_PATH}/ocp-dev-preview/latest-$1/openshift-install-${OS}.tar.gz"
    download "$CLIENT" "$INSTALL"
  fi

}

download(){

echo -n "Downloading $(echo $1 | awk -F/ '{ print $NF }'):    "
wget --progress=dot "$1" -O "/tmp/$(echo $1 | awk -F/ '{ print $NF }')" 2>&1 | \
    grep --line-buffered "%" | \
    sed -e "s,\.,,g" | \
    awk '{printf("\b\b\b\b%4s", $2)}'
echo -ne "\b\b\b\b"
echo " Download Complete."

echo -n "Downloading $(echo $2 | awk -F/ '{ print $NF }'):    "
wget --progress=dot "$2" -O "/tmp/$(echo $2 | awk -F/ '{ print $NF }')" 2>&1 | \
    grep --line-buffered "%" | \
    sed -e "s,\.,,g" | \
    awk '{printf("\b\b\b\b%4s", $2)}'
echo -ne "\b\b\b\b"
echo " Download Complete."

backup extract

}

backup() {

  CUR_VERSION=$(oc version 2>/dev/null | grep Client | sed -e 's/Client Version: //')
  if [[ -f "${BIN_PATH}/oc" ]] && [[ -f "${BIN_PATH}/openshift-install" ]] && [[ -f "${BIN_PATH}/kubectl" ]]
  then
      for i in openshift-install oc kubectl; do mv "$(which $i)" ${BIN_PATH}/"$i"."$CUR_VERSION".bak; done
  fi

  if [[ "$1" == "extract" ]]; then
    extract cleanup
  fi

}

extract() {

  echo -e "\nExtracting oc and kubectl from openshift-client-${OS}.tar.gz to ${BIN_PATH}"
  tar -zxf "/tmp/openshift-client-${OS}.tar.gz" -C ${BIN_PATH}
  echo -e "\nExtracting openshift-install from openshift-install-${OS}.tar.gz to ${BIN_PATH}"
  tar -zxf "/tmp/openshift-install-${OS}.tar.gz" -C ${BIN_PATH}

  if [[ "$1" == "cleanup" ]]; then
    cleanup
  fi

}

cleanup() {

  rm -rf ${BIN_PATH}/README.md
  rm -rf "/tmp/openshift-client-${OS}.tar.gz"
  rm -rf "/tmp/openshift-install-${OS}.tar.gz"

  show_ver

}

remove_old_ver() {

  if ls ${BIN_PATH}/oc*bak 1> /dev/null 2>&1 && ls ${BIN_PATH}/openshift-install*bak 1> /dev/null 2>&1 && ls ${BIN_PATH}/kubectl*bak 1> /dev/null 2>&1
  then
  read -rp "Delete the following files?
$(echo -e "\n")
$(for i in oc kubectl openshift-install; do ls -1 ${BIN_PATH}/$i*bak 2>/dev/null; done)
$(echo -e "\nY/N? ")"

  if [[ $REPLY =~ ^[Yy]$ ]]
  then
    for i in oc kubectl openshift-install; do rm -f ${BIN_PATH}/$i*bak 2>/dev/null; done
    exit 0
  elif [[ $REPLY =~ ^[Nn]$ ]]
  then
    exit 0
  else
    echo "Invalid response."
    exit 1
  fi
else
  echo "No previous versions found."
  exit 0
fi

}

uninstall(){

  check_root

	if ls ${BIN_PATH}/oc 1> /dev/null 2>&1 && ls ${BIN_PATH}/openshift-install 1> /dev/null 2>&1 && ls ${BIN_PATH}/kubectl 1> /dev/null 2>&1
  then
  read -rp "Delete the following files?
$(echo -e "\n")
$(for i in oc kubectl openshift-install; do ls -1 ${BIN_PATH}/$i 2>/dev/null; done)
$(for i in oc kubectl openshift-install; do ls -1 ${BIN_PATH}/$i*bak 2>/dev/null; done)
$(echo -e "\nY/N? ")"

  if [[ $REPLY =~ ^[Yy]$ ]]
  then
    for i in oc kubectl openshift-install; do rm -f ${BIN_PATH}/$i*bak 2>/dev/null; done
    for i in oc kubectl openshift-install; do rm -f ${BIN_PATH}/$i 2>/dev/null; done
    exit 0
  elif [[ $REPLY =~ ^[Nn]$ ]]
  then
    exit 0
  else
    echo "Invalid response."
    exit 1
  fi
else
  echo "No versions found."
  exit 0
fi

}

show_ver() {

  if which oc &>/dev/null; then
      echo -e "\noc version: $(oc version 2>/dev/null | grep Client | sed -e 's/Client Version: //')"
  else
      echo "Error getting oc version. Please rerun script."
  fi

  if which kubectl &>/dev/null; then
      echo -e "\nkubectl version: $(kubectl version --client | grep -o "GitVersion:.*" | cut -d, -f1)"
  else
      echo "Error getting kubectl version. Please rerun script."
  fi

  if which openshift-install &>/dev/null; then
      echo -e "\nopenshift-install version: $(openshift-install version | grep openshift-install | sed -e 's/openshift-install //')"
  else
      echo "Error getting openshift-install version. Please rerun script."
  fi

}

cli(){

  case "$1" in
    butane)
      cli_path "butane"
      ;;
    coreos-installer)
      cli_path "coreos-installer"
      ;;
    helm)
      cli_path "helm"
      ;;
    kam)
      cli_path "kam"
      ;;
    odo)
      cli_path "odo"
      ;;
    serverless)
      cli_path "serverless"
      ;;
    *)
      cli_path "help"
      ;;
  esac

}

cli_path(){

  if [[ "$1" == "help" ]]
  then
    echo "Please enter butane, coreos-installer, helm, kam, odo, or serverless."
    exit 0
  fi

  if [[ "$1" == "butane" ]]
  then
    if [ "$OS" == "mac" ] && [ "$ARCH" == "x86_64" ]
    then
      MIRROR_CLI_PATH="${MIRROR_DOMAIN}/pub/openshift-v4/clients/butane/latest/butane-darwin-${ARCH}"
    elif [ "$OS" != "mac" ] && [ "$ARCH" == "x86_64" ]
    then
      MIRROR_CLI_PATH="${MIRROR_DOMAIN}/pub/openshift-v4/clients/butane/latest/butane-amd64"
    else
      MIRROR_CLI_PATH="${MIRROR_DOMAIN}/pub/openshift-v4/clients/butane/latest/butane-${ARCH}"
    fi
  fi

  if [[ "$1" == "coreos-installer" ]]
  then
    if [ "$ARCH" == "x86_64" ]
      then
        MIRROR_CLI_PATH="${MIRROR_DOMAIN}/pub/openshift-v4/clients/coreos-installer/latest/coreos-installer_amd64"
      else
        MIRROR_CLI_PATH="${MIRROR_DOMAIN}/pub/openshift-v4/clients/coreos-installer/latest/coreos-installer_$ARCH"
    fi
  fi

  if [[ "$1" == "helm" ]]
  then
    if [ "$OS" == "mac" ] && [ "$ARCH" == "x86_64" ]
    then
      MIRROR_CLI_PATH="${MIRROR_DOMAIN}/pub/openshift-v4/clients/helm/latest/helm-darwin-${ARCH}"
    elif [ "$OS" != "mac" ] && [ "$ARCH" == "x86_64" ]
    then
      MIRROR_CLI_PATH="${MIRROR_DOMAIN}/pub/openshift-v4/clients/helm/latest/helm-linux-amd64"
    else
      MIRROR_CLI_PATH="${MIRROR_DOMAIN}/pub/openshift-v4/clients/helm/latest/helm-linux-${ARCH}"
    fi
  fi

  if [[ "$1" == "kam" ]]
  then
    if [ "$OS" == "mac" ] && [ "$ARCH" == "x86_64" ]
    then
      MIRROR_CLI_PATH="${MIRROR_DOMAIN}/pub/openshift-v4/clients/kam/latest/kam-darwin-${ARCH}"
    elif [ "$OS" != "mac" ] && [ "$ARCH" == "x86_64" ]
    then
      MIRROR_CLI_PATH="${MIRROR_DOMAIN}/pub/openshift-v4/clients/kam/latest/kam-linux-amd64"
    else
      MIRROR_CLI_PATH="${MIRROR_DOMAIN}/pub/openshift-v4/clients/kam/latest/kam-linux-${ARCH}"
    fi
  fi

  if [[ "$1" == "odo" ]]
  then
    if [ "$OS" == "mac" ] && [ "$ARCH" == "x86_64" ]
    then
      MIRROR_CLI_PATH="${MIRROR_DOMAIN}/pub/openshift-v4/clients/odo/latest/odo-darwin-${ARCH}"
    elif [ "$OS" == "mac" ] && [ "$ARCH" == "arm64" ]
    then
      MIRROR_CLI_PATH="${MIRROR_DOMAIN}/pub/openshift-v4/clients/odo/latest/odo-darwin-${ARCH}"
    elif [ "$ARCH" == "x86_64" ]
    then
      MIRROR_CLI_PATH="${MIRROR_DOMAIN}/pub/openshift-v4/clients/odo/latest/odo-linux-amd64"
    else
      MIRROR_CLI_PATH="${MIRROR_DOMAIN}/pub/openshift-v4/clients/odo/latest/odo-linux-${ARCH}"
    fi
  fi

  if [[ "$1" == "serverless" ]]
  then
    if [ "$OS" == "mac" ]
    then
      MIRROR_CLI_PATH="${MIRROR_DOMAIN}/pub/openshift-v4/clients/serverless/latest/kn-macos-amd64.tar.gz"
    elif [ "$ARCH" == "x86_64" ]
    then
      MIRROR_CLI_PATH="${MIRROR_DOMAIN}/pub/openshift-v4/clients/serverless/latest/kn-linux-amd64.tar.gz"
    else
      MIRROR_CLI_PATH="${MIRROR_DOMAIN}/pub/openshift-v4/clients/serverless/latest/kn-linux-${ARCH}.tar.gz"
    fi
  fi

  download_cli $MIRROR_CLI_PATH "$1"

}

download_cli(){

check_root

filename=$(echo $1 | awk -F/ '{ print $NF }')
echo -n "Downloading $filename:    "
wget --progress=dot "$1" -O "/tmp/$(echo $1 | awk -F/ '{ print $NF }')" 2>&1 | \
    grep --line-buffered "%" | \
    sed -e "s,\.,,g" | \
    awk '{printf("\b\b\b\b%4s", $2)}'
echo -ne "\b\b\b\b"
echo " Download Complete."

if [[ "$2" == "serverless" ]]; then
  tar -zxf "/tmp/$(echo $1 | awk -F/ '{ print $NF }')" -C ${BIN_PATH}
  rm "/tmp/$(echo $1 | awk -F/ '{ print $NF }')"
else
  cp "/tmp/$(echo $1 | awk -F/ '{ print $NF }')" ${BIN_PATH}
  chmod +x "${BIN_PATH}/$filename"
fi

}

show_help() {

cat  << ENDHELP
USAGE: $(basename "$0")
install-oc-tools is a small script that will download the latest, stable, fast, nightly,
or specified version of the oc command line tools, kubectl, and openshift-install.
If a previous version of the tools are installed it will make a backup of the file.

Options:
    --latest:  Installs the latest specified version. If no version is specified then it
               downloads the latest stable version of the oc tools.
      Example: install-oc-tools --latest 4.10
    --update:  Same as --latest
    --fast:    Installs the latest fast version. If no version is specified then it downloads
               the latest fast version.
      Example: install-oc-tools --fast 4.10
    --stable:  Installs the latest stable version. If no version is specified then it
               downloads the latest stable version of the oc tools.
      Example: install-oc-tools --stable 4.10
  --candidate: Installs the candidate version. If no version is specified then it
               downloads the latest candidate version of the oc tools.
      Example: install-oc-tools --candidate 4.10
    --version: Installs the specific version.  If no version is specified then it
               downloads the latest stable version of the oc tools.
      Example: install-oc-tools --version 4.10.10
    --info:    Displays Errata URL, Kubernetes Version, and versions it can be upgraded from.
      Example: install-oc-tools --info 4.10
      Example: install-oc-tools --info 4.10.5
    --nightly: Installs the latest nightly version. If you do not specify a version it will grab
               the latest version.
      Example: install-oc-tools --nightly
    --cleanup: This deleted all backed up version of oc, kubectl, and openshift-install
      Example: install-oc-tools --cleanup
  --uninstall: This will delete all copies of oc, kubectl, and openshift-install including backups
      Example: install-oc-tools --uninstall
        --cli: Allows you to install butane, coreos-installer, helm, kam, odo, or serverless
      Example: install-oc-tools --cli butane
    --help:    Shows this help message

You may override the binary path by setting it in ${OCTOOLSRC}:
- BIN_PATH: Where to save the oc tools. Default: /usr/local/bin

Example octoolsrc:
BIN_PATH=/root/bin

ENDHELP

}

main() {

  check_prereq

  setup

  run "$1" "$2"

}

main "$@"
