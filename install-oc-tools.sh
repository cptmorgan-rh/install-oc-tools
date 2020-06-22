#!/usr/bin/env bash

set -e
OS=$(uname -s)
MIRROR_DOMAIN='https://mirror.openshift.com/'
MIRROR_PATH='/pub/openshift-v4/clients/ocp/'
MIRROR_FILE="${MIRROR_DOMAIN}${MIRROR_PATH}/stable-${1}/openshift-install-${OS}.tar.gz"

if [ "${OS}" == 'Linux' ]; then 
	OS=linux
elif [ "${OS}" == 'Darwin' ]; then 
	OS=mac 
else 
	echo "OS Unsupported: ${OS}"
	exit 99
fi

run() {
  case "$1" in
    --fast)
      fast "$2"
      ;;
    --latest)
      latest "$2"
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
    --stable)
      stable "$2"
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
    *)
      show_help
      exit 0
  esac
}

restore_latest(){

  if [[ "$1" == "" ]]; then
    VERSION=$(curl -s "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/release.txt" | grep 'Name:' | awk '{print $NF}')
    if ls "/usr/local/bin/oc.${VERSION}.bak" 1> /dev/null 2>&1 && ls "/usr/local/bin/openshift-install.${VERSION}.bak" 1> /dev/null 2>&1 && ls "/usr/local/bin/kubectl.${VERSION}.bak" 1> /dev/null 2>&1
    then
      read -p "Found backup of version ${VERSION}. Restore?
    $(echo -e "\nY/N? ")"
      if [[ $REPLY =~ ^[Yy]$ ]]
      then
        backup
        for i in openshift-install oc kubectl; do mv "/usr/local/bin/${i}.${VERSION}.bak" "/usr/local/bin/${i}"; done
        show_ver
        exit 0
      elif [[ $REPLY =~ ^[Nn]$ ]]
      then
        echo "Downloading files..."
      fi
    fi
  else
    VERSION=$(curl -s "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest-$1/release.txt" | grep 'Name:' | awk '{print $NF}')
    if ls "/usr/local/bin/oc.${VERSION}.bak" 1> /dev/null 2>&1 && ls "/usr/local/bin/openshift-install.${VERSION}.bak" 1> /dev/null 2>&1 && ls "/usr/local/bin/kubectl.${VERSION}.bak" 1> /dev/null 2>&1
    then
      read -p "Found backup of version ${VERSION}. Restore?
    $(echo -e "\nY/N? ")"
      if [[ $REPLY =~ ^[Yy]$ ]]
      then
        backup
        for i in openshift-install oc kubectl; do mv "/usr/local/bin/${i}.${VERSION}.bak" "/usr/local/bin/${i}"; done
        show_ver
        exit 0
      elif [[ $REPLY =~ ^[Nn]$ ]]
      then
        echo "Downloading files..."
      fi
    fi
  fi

}

restore_fast(){

  if [[ "$1" == "" ]]; then
    VERSION=$(curl -s "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/fast/release.txt" | grep 'Name:' | awk '{print $NF}')
    if ls "/usr/local/bin/oc.${VERSION}.bak" 1> /dev/null 2>&1 && ls "/usr/local/bin/openshift-install.${VERSION}.bak" 1> /dev/null 2>&1 && ls "/usr/local/bin/kubectl.${VERSION}.bak" 1> /dev/null 2>&1
    then
      read -p "Found backup of version ${VERSION}. Restore?
    $(echo -e "\nY/N? ")"
      if [[ $REPLY =~ ^[Yy]$ ]]
      then
        backup
        for i in openshift-install oc kubectl; do mv "/usr/local/bin/${i}.${VERSION}.bak" "/usr/local/bin/${i}"; done
        show_ver
        exit 0
      elif [[ $REPLY =~ ^[Nn]$ ]]
      then
        echo "Downloading files..."
      fi
    fi
  else
    VERSION=$(curl -s "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/fast-$1/release.txt" | grep 'Name:' | awk '{print $NF}')
    if ls "/usr/local/bin/oc.${VERSION}.bak" 1> /dev/null 2>&1 && ls "/usr/local/bin/openshift-install.${VERSION}.bak" 1> /dev/null 2>&1 && ls "/usr/local/bin/kubectl.${VERSION}.bak" 1> /dev/null 2>&1
    then
      read -p "Found backup of version ${VERSION}. Restore?
    $(echo -e "\nY/N? ")"
      if [[ $REPLY =~ ^[Yy]$ ]]
      then
        backup
        for i in openshift-install oc kubectl; do mv "/usr/local/bin/${i}.${VERSION}.bak" "/usr/local/bin/${i}"; done
        show_ver
        exit 0
      elif [[ $REPLY =~ ^[Nn]$ ]]
      then
        echo "Downloading files..."
      fi
    fi
  fi

}

restore_stable(){

  if [[ "$1" == "" ]]; then
    VERSION=$(curl -s "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/release.txt" | grep 'Name:' | awk '{print $NF}')
    if ls "/usr/local/bin/oc.${VERSION}.bak" 1> /dev/null 2>&1 && ls "/usr/local/bin/openshift-install.${VERSION}.bak" 1> /dev/null 2>&1 && ls "/usr/local/bin/kubectl.${VERSION}.bak" 1> /dev/null 2>&1
    then
      read -p "Found backup of version ${VERSION}. Restore?
    $(echo -e "\nY/N? ")"
      if [[ "$REPLY" =~ ^[Yy]$ ]]
      then
        backup
        for i in openshift-install oc kubectl; do mv "/usr/local/bin/${i}.${VERSION}.bak" "/usr/local/bin/${i}"; done
        show_ver
        exit 0
      elif [[ "$REPLY" =~ ^[Nn]$ ]]
      then
        echo "Downloading files..."
      fi
    fi
  else
    VERSION=$(curl -s "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable-${1}/release.txt" | grep 'Name:' | awk '{print $NF}')
    if ls "/usr/local/bin/oc.${VERSION}.bak" 1> /dev/null 2>&1 && ls "/usr/local/bin/openshift-install.${VERSION}.bak" 1> /dev/null 2>&1 && ls "/usr/local/bin/kubectl.${VERSION}.bak" 1> /dev/null 2>&1
    then
      read -p "Found backup of version ${VERSION}. Restore?
    $(echo -e "\nY/N? ")"
      if [[ $REPLY =~ ^[Yy]$ ]]
      then
        backup
        for i in openshift-install oc kubectl; do mv "/usr/local/bin/${i}.${VERSION}.bak" "/usr/local/bin/${i}"; done
        show_ver
        exit 0
      elif [[ $REPLY =~ ^[Nn]$ ]]
      then
        echo "Downloading files..."
      fi
    fi
  fi

}


restore_version(){

  if ls "/usr/local/bin/oc.${1}.bak" 1> /dev/null 2>&1 && ls "/usr/local/bin/openshift-install.${1}.bak" 1> /dev/null 2>&1 && ls "/usr/local/bin/kubectl.${1}.bak" 1> /dev/null 2>&1
  then
    read -p "Found backup of version $1. Restore?
  $(echo -e "\nY/N? ")"
  if [[ $REPLY =~ ^[Yy]$ ]]
  then
    backup
    for i in openshift-install oc kubectl; do mv "/usr/local/bin/${i}.${1}.bak" "/usr/local/bin/${i}"; done
    show_ver
    exit 0
  elif [[ $REPLY =~ ^[Nn]$ ]]
  then
    echo "Downloading files..."
  fi
  fi
}

version_info(){

  status_code=$(curl --write-out "%{http_code}" --silent --output /dev/null "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/$1/release.txt")

  if [[ "$status_code" -ne 200 ]]; then
    echo "$1 does not exist"
    exit 1
  else

  releasetext="https://mirror.openshift.com/pub/openshift-v4/clients/ocp/$1/release.txt"

  errata_url=$(curl --silent "${releasetext}" 2>/dev/null | grep url | sed -e 's/    url: //')
  k8s_ver=$(curl --silent "${releasetext}" 2>/dev/null | grep -m1 kubernetes | sed -e 's/  kubernetes //')
  upgrades=$(curl --silent "${releasetext}" 2>/dev/null | grep Upgrades | sed -e 's/  Upgrades: //')

  echo "$1 Version Info:"
  echo -e "\nKubernetes Version: $k8s_ver"
  echo -e "\n$1 can be upgraded from the following versions: $upgrades"
  echo -e "\nErrata: $errata_url"
  exit 0

fi

}

version() {

  restore_version "$1"

  if [[ "$1" == "" ]]; then
    echo "Please specify a version."
    echo "Example: install-oc-tools --version 4.4.6"
    exit 1
  fi

  status_code=$(curl --write-out "%{http_code}" --silent --output /dev/null "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/$1/release.txt")

  if [[ "$status_code" -ne 200 ]]; then
    echo "$1 does not exist"
    exit 1
  else
    VERSION=$(curl -s "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/$1/release.txt" | grep 'Name:' | awk '{print $NF}')
    CUR_VERSION=$(oc version 2>/dev/null | grep Client | sed -e 's/Client Version: //')
    if [ "$VERSION" == "$CUR_VERSION" ]; then
      echo "${VERSION} already installed."
      exit 0
    fi
    wget -q "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/$1/openshift-client-${OS}.tar.gz"  -O "/tmp/openshift-client-${OS}.tar.gz"
    wget -q "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/$1/openshift-install-${OS}.tar.gz" -O "/tmp/openshift-install-${OS}.tar.gz"
  fi

}

latest() {

  restore_latest "$1"

  if [[ "$1" == "" ]]; then
    VERSION=$(curl -s "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/release.txt" | grep 'Name:' | awk '{print $NF}')
    CUR_VERSION=$(oc version 2>/dev/null | grep Client | sed -e 's/Client Version: //')
      if [ "$VERSION" == "$CUR_VERSION" ]; then
        echo "${VERSION} is installed."
        exit 0
      fi
    wget -q "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-${OS}.tar.gz"  -O "/tmp/openshift-client-${OS}.tar.gz"
    wget -q "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-install-${OS}.tar.gz" -O "/tmp/openshift-install-${OS}.tar.gz"
  else
    VERSION=$(curl -s "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest-$1/release.txt" | grep 'Name:' | awk '{print $NF}')
    CUR_VERSION=$(oc version 2>/dev/null | grep Client | sed -e 's/Client Version: //')
    if [ "$VERSION" == "$CUR_VERSION" ]; then
      echo "${VERSION} already installed."
      exit 0
    fi
    wget -q "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest-$1/openshift-client-${OS}.tar.gz"  -O "/tmp/openshift-client-${OS}.tar.gz"
    wget -q "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest-$1/openshift-install-${OS}.tar.gz" -O "/tmp/openshift-install-${OS}.tar.gz"
  fi

}

fast() {

  restore_fast "$1"

  if [[ "$1" == "" ]]; then
    VERSION=$(curl -s "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/fast/release.txt" | grep 'Name:' | awk '{print $NF}')
    CUR_VERSION=$(oc version 2>/dev/null | grep Client | sed -e 's/Client Version: //')
      if [ "$VERSION" == "$CUR_VERSION" ]; then
        echo "${VERSION} is installed."
        exit 0
      fi
    wget -q "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/fast/openshift-client-${OS}.tar.gz"  -O "/tmp/openshift-client-${OS}.tar.gz"
    wget -q "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/fast/openshift-install-${OS}.tar.gz" -O "/tmp/openshift-install-${OS}.tar.gz"
  else
    VERSION=$(curl -s "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/fast-$1/release.txt" | grep 'Name:' | awk '{print $NF}')
    CUR_VERSION=$(oc version 2>/dev/null | grep Client | sed -e 's/Client Version: //')
    if [ "$VERSION" == "$CUR_VERSION" ]; then
      echo "${VERSION} already installed."
      exit 0
    fi
    wget -q "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/fast-$1/openshift-client-${OS}.tar.gz"  -O "/tmp/openshift-client-${OS}.tar.gz"
    wget -q "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/fast-$1/openshift-install-${OS}.tar.gz" -O "/tmp/openshift-install-${OS}.tar.gz"
  fi

}

stable() {

  restore_stable "$1"

  if [[ "$1" == "" ]]; then
    VERSION=$(curl -s "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/release.txt" | grep 'Name:' | awk '{print $NF}')
    CUR_VERSION=$(oc version 2>/dev/null | grep Client | sed -e 's/Client Version: //')
      if [ "$VERSION" == "$CUR_VERSION" ]; then
        echo "${VERSION} is installed."
        exit 0
      fi
    wget -q "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/openshift-client-${OS}.tar.gz"  -O "/tmp/openshift-client-${OS}.tar.gz"
    wget -q "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/openshift-install-${OS}.tar.gz" -O "/tmp/openshift-install-${OS}.tar.gz"
  else
    VERSION=$(curl -s "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable-$1/release.txt" | grep 'Name:' | awk '{print $NF}')
    CUR_VERSION=$(oc version 2>/dev/null | grep Client | sed -e 's/Client Version: //')
    if [ "$VERSION" == "$CUR_VERSION" ]; then
      echo "${VERSION} already installed."
      exit 0
    fi
    wget -q "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable-$1/openshift-client-${OS}.tar.gz"  -O "/tmp/openshift-client-${OS}.tar.gz"
    wget -q "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable-$1/openshift-install-${OS}.tar.gz" -O "/tmp/openshift-install-${OS}.tar.gz"
  fi

}

nightly() {

  if [[ "$1" == "" ]]; then
    VERSION=$(curl -s "http://mirror.openshift.com/pub/openshift-v4/clients/ocp-dev-preview/latest/release.txt" | grep 'Name:' | awk '{print $NF}')
    CUR_VERSION=$(oc version 2>/dev/null | grep Client | sed -e 's/Client Version: //')
      if [ "$VERSION" == "$CUR_VERSION" ]; then
        echo "${VERSION} is installed."
        exit 0
      fi
      wget -q "http://mirror.openshift.com/pub/openshift-v4/clients/ocp-dev-preview/latest/openshift-client-${OS}.tar.gz"  -O "/tmp/openshift-client-${OS}.tar.gz"
      wget -q "http://mirror.openshift.com/pub/openshift-v4/clients/ocp-dev-preview/latest/openshift-install-${OS}.tar.gz" -O "/tmp/openshift-install-${OS}.tar.gz"
  else
    VERSION=$(curl -s "http://mirror.openshift.com/pub/openshift-v4/clients/ocp-dev-preview/latest-$1/release.txt" | grep 'Name:' | awk '{print $NF}')
    CUR_VERSION=$(oc version 2>/dev/null | grep Client | sed -e 's/Client Version: //')
    if [ "$VERSION" == "$CUR_VERSION" ]; then
      echo "${VERSION} already installed."
      exit 0
    fi
    wget -q "http://mirror.openshift.com/pub/openshift-v4/clients/ocp-dev-preview/latest-$1/openshift-client-${OS}.tar.gz -O /tmp/openshift-client-${OS}.tar.gz"
    wget -q "http://mirror.openshift.com/pub/openshift-v4/clients/ocp-dev-preview/latest-$1/openshift-install-${OS}.tar.gz -O /tmp/openshift-install-${OS}.tar.gz"
  fi

}

backup() {

  CUR_VERSION=$(oc version 2>/dev/null | grep Client | sed -e 's/Client Version: //')
  if [[ -f "/usr/local/bin/oc" ]] && [[ -f "/usr/local/bin/openshift-install" ]] && [[ -f "/usr/local/bin/kubectl" ]]
  then
      for i in openshift-install oc kubectl; do mv "$(which $i)" /usr/local/bin/"$i"."$CUR_VERSION".bak; done
  fi
}

extract() {
  tar -zxf "/tmp/openshift-client-${OS}.tar.gz" -C /usr/local/bin
  tar -zxf "/tmp/openshift-install-${OS}.tar.gz" -C /usr/local/bin
}

cleanup() {
  rm -rf /usr/local/bin/README.md
  rm -rf "/tmp/openshift-client-${OS}.tar.gz"
  rm -rf "/tmp/openshift-install-${OS}.tar.gz"
}

remove_old_ver() {

  if ls /usr/local/bin/oc*bak 1> /dev/null 2>&1 && ls /usr/local/bin/openshift-install*bak 1> /dev/null 2>&1 && ls /usr/local/bin/kubectl*bak 1> /dev/null 2>&1
  then
  read -rp "Delete the following files?
$(echo -e "\n")
$(for i in oc kubectl openshift-install; do ls -1 /usr/local/bin/$i*bak 2>/dev/null; done)
$(echo -e "\nY/N? ")"

  if [[ $REPLY =~ ^[Yy]$ ]]
  then
    for i in oc kubectl openshift-install; do rm -f /usr/local/bin/$i*bak 2>/dev/null; done
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

show_help() {
    cat  << ENDHELP
USAGE: install-oc-tools
install-oc-tools is a small script that will download the latest, stable, fast, nightly,
or specified version of the oc command line tools, kubectl, and openshift-install.
If a previous version of the tools are installed it will make a backup of the file.

Options:
  --latest:  Installs the latest specified version. If no version is specified then it
             downloads the latest stable version of the oc tools.
    Example: install-oc-tools --latest 4.4
  --update:  Same as --latest
  --fast:    Installs the latest fast version. If no version is specified then it downloads
             the latest fast version.
    Example: install-oc-tools --fast 4.4
  --stable:  Installs the latest stable version. If no version is specified then it
             downloads the latest stable version of the oc tools.
    Example: install-oc-tools --stable 4.4
  --version: Installs the specific version.  If no version is specified then it
             downloads the latest stable version of the oc tools.
    Example: install-oc-tools --version 4.4.6
  --info:    Displays Errata URL, Kubernetes Version, and versions it can be upgraded from.
    Example: install-oc-tools --ver_info 4.4.6
  --nightly: Installs the latest nightly version. If you do not specify a version it will grab
             the latest version.
    Example: install-oc-tools --nightly 4.4
             install-oc-tools --nightly
  --cleanup: This deleted all backed up version of oc, kubectl, and openshift-install
    Example: install-oc-tools --cleanup
  --help:    Shows this help message
ENDHELP
}

main() {
  if [ "$EUID" -ne 0 ]
  then echo "This script requires root access to run."
  exit
  fi
  run "$1" "$2"

  backup

  extract

  cleanup

  show_ver
}

main "$@"
