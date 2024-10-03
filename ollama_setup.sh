#!/bin/bash

CONTAINER_NAME=$1
USER_NAME="UMDadmin"
USER_PASSWORD="password"

# Check if container name is provided
if [ -z "$CONTAINER_NAME" ]; then
    echo "Error: Container name is required."
    echo "Usage: $0 <container-name>"
    exit 1
fi

# Step 1: Create the container
echo "Creating LXC container '$CONTAINER_NAME'..."
sudo lxc-create -n "$CONTAINER_NAME" -t download -- -d ubuntu -r focal -a amd64

# Step 2: Start the container
echo "Starting LXC container '$CONTAINER_NAME'..."
sudo lxc-start -n "$CONTAINER_NAME"

# Wait for the container to fully start
sleep 10

# Step 3: Attach to the container to create the user
echo "Attaching to the container to create user '$USER_NAME'..."

sudo lxc-attach -n "$CONTAINER_NAME" -- bash -c "
    # Create the user with the password 'password'
    echo 'Creating user $USER_NAME with password $USER_PASSWORD...'
    useradd -m -s /bin/bash $USER_NAME
    echo '$USER_NAME:$USER_PASSWORD' | chpasswd

    # Add user to the sudo group
    usermod -aG sudo $USER_NAME
    echo 'User $USER_NAME created and added to sudo group.'
"

echo "Container '$CONTAINER_NAME' created and user '$USER_NAME' added successfully!"


sudo lxc-attach -n "$CONTAINER_NAME" -- apt update
sudo lxc-attach -n "$CONTAINER_NAME" -- apt install -y openssh-server
sudo lxc-attach -n "$CONTAINER_NAME" -- systemctl start ssh
sudo lxc-attach -n "$CONTAINER_NAME" -- systemctl enable ssh

# Step 4: Add User

sudo apt-get install sshpass

REMOTE_IP=$(sudo lxc-attach -n "$CONTAINER_NAME" -- bash -c "hostname -I | awk '{print \$1}'")

# Check if the IP was found
if [ -z "$REMOTE_IP" ]; then
    echo "Error: Could not retrieve IP address for container '$CONTAINER_NAME'."
    exit 1
fi

# Define variables
REMOTE_USER="UMDadmin"




# Transfer /usr/share/ollama directory
echo "Transferring /usr/local/bin/ollama to ${REMOTE_USER}@${REMOTE_IP}:${DESTINATION_PATH}..."
sudo sshpass -p "$USER_PASSWORD" scp -o StrictHostKeyChecking=no -r /usr/share/ollama ${REMOTE_USER}@${REMOTE_IP}:~/AIfiles

# Transfer /usr/share/ollama/.ollama directory
echo "Transferring /usr/share/ollama/.ollama to ${REMOTE_USER}@${REMOTE_IP}:${DESTINATION_PATH}..."
sudo sshpass -p "$USER_PASSWORD" scp -o StrictHostKeyChecking=no -r "/usr/local/bin/ollama" ${REMOTE_USER}@${REMOTE_IP}:~/ollama

sudo lxc-attach -n "$CONTAINER_NAME" -- bash -c "mv /home/UMDadmin/ollama /usr/local/bin/ollama"

#Replace this line with a model file download
sudo lxc-attach -n "$CONTAINER_NAME" -- bash -c "mv /home/UMDadmin/AIfiles /usr/share/ollama"

echo "File transfer completed."

echo "Setting up Ollama"
