install-oc-tools - OpenShift 4 Tools Installer
===========================================

DESCRIPTION
------------

Many OpenShift Developers and Administrators do not use Red Hat Enterprise Linux as their desktop. Instead many use Fedora, MacOS, Arch, Manjaro, Ubuntu, etc. This puts them in a tough situation when it comes to getting the OpenShift 4 CLI tools. You can manually go to [mirror.openshift.com](https://mirror.openshift.com) and download the tarballs, extract them, and copy them over. You can also download the latest client from the OpenShift console. Also, what do you do if you have multiple clusters running different version? A QA cluster on Candidate version and a Production version on the previous release?

Now there is a simple solution. install-oc-tools is a small script that will download or restore the latest, stable, fast, nightly, or specified version of the oc command line tools, kubectl, and openshift-install and copy them to /usr/local/bin.

If a previous version of the OpenShift command line tools are already installed it will make a backup of the file.


DEMO
------------
[![asciicast](https://asciinema.org/a/C8PUe0CHY69u9V44jmzygmsVQ.svg)](https://asciinema.org/a/C8PUe0CHY69u9V44jmzygmsVQ)

INSTALLATION
------------
* Copy install-oc-tools to /usr/local/bin

AUTHOR
------
Morgan Peterman
