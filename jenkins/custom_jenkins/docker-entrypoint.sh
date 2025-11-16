#!/bin/bash
set -e

# Detect docker.sock GID
DOCKER_GID=$(stat -c '%g' /var/run/docker.sock)

# Switch to root if necessary
sudo_group_setup() {
  if ! getent group $DOCKER_GID >/dev/null; then
    echo "Creating docker group with GID $DOCKER_GID"
    groupadd -g $DOCKER_GID docker
  fi
  usermod -aG $DOCKER_GID jenkins
}

# Set up with root privilege
if [ "$(id -u)" = "0" ]; then
  sudo_group_setup
# Switch back to jenkin user
  exec su jenkins -c "/usr/bin/tini -- /usr/local/bin/jenkins.sh"
else
  exec /usr/bin/tini -- /usr/local/bin/jenkins.sh
fi
