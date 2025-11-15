#!/bin/bash
set -e

# Detect GID của docker.sock
DOCKER_GID=$(stat -c '%g' /var/run/docker.sock)

# Switch sang root để sửa group (nếu cần)
sudo_group_setup() {
  if ! getent group $DOCKER_GID >/dev/null; then
    echo "Creating docker group with GID $DOCKER_GID"
    groupadd -g $DOCKER_GID docker
  fi
  usermod -aG $DOCKER_GID jenkins
}

# Thực hiện setup với quyền root
if [ "$(id -u)" = "0" ]; then
  sudo_group_setup
  # Quay lại chạy bằng user jenkins
  exec su jenkins -c "/usr/bin/tini -- /usr/local/bin/jenkins.sh"
else
  exec /usr/bin/tini -- /usr/local/bin/jenkins.sh
fi
