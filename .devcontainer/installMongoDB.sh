#!/bin/bash

# Install MongoDB Community Edition from Debian repository instead
# This avoids the SHA1 signature issue with the official MongoDB repo
sudo apt-get update
sudo apt-get install -y mongodb

# If mongodb package is not available, create user manually and use mongod from alternative source
if ! command -v mongod &> /dev/null; then
    echo "MongoDB not available in Debian repos, installing from official repo with workarounds..."

    # Detect operating system to avoid configuring Ubuntu-specific repositories on non-Ubuntu systems
    if [ -r /etc/os-release ]; then
        . /etc/os-release
    fi

    MONGO_REPO_ADDED=0

    if [ "${ID}" = "ubuntu" ] && [ "${VERSION_CODENAME}" = "jammy" ]; then
        # Add MongoDB repository for Ubuntu jammy (with updated GPG key handling)
        curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/mongodb-server-8.0.gpg
        echo "deb [ arch=amd64,arm64 signed-by=/etc/apt/trusted.gpg.d/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/8.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list

        sudo apt-get update
        MONGO_REPO_ADDED=1
    else
        echo "Not running on Ubuntu jammy (detected: ${ID:-unknown} ${VERSION_CODENAME:-unknown});"
        echo "Skipping Ubuntu-specific MongoDB repository configuration. Please configure an appropriate MongoDB repository for this distribution if needed."
    fi

    # If repository was added, attempt installation; otherwise fall back to creating the mongodb user
    if [ "$MONGO_REPO_ADDED" -eq 1 ]; then
        # If install still fails, create the mongodb user manually
        if ! sudo apt-get install -y mongodb-org; then
            echo "Package installation failed, creating mongodb user manually..."
            sudo useradd -r -s /bin/false mongodb || true
        fi
    else
        echo "MongoDB repository not configured; creating mongodb user manually as a fallback..."
        sudo useradd -r -s /bin/false mongodb || true
    fi
fi

# Create necessary directories and set permissions
sudo mkdir -p /data/db

# Use mongodb user if it exists, otherwise use current user
if id "mongodb" &>/dev/null; then
    sudo chown -R mongodb:mongodb /data/db
else
    echo "MongoDB user not found, using current user for /data/db"
    sudo chown -R "$USER":"$USER" /data/db
fi
