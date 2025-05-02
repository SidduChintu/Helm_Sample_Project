#!/bin/bash

# Step 1: Ensure arguments are provided
#if [ "$#" -lt 4 ]; then
#    echo "Usage: $0 <docker-image(onlyimagename)> <image_tag> <emp-id> <aws_node1> <aws-node2>"
#    exit 1
#fi

# Function to display usage
usage() {
    echo "Usage: $0 <image_name> <tag> <empid> <aws_node1> <aws_node2> ..... <aws_nodeN>"
    echo "Please provide the arguments in the following order:"
    echo "1. image_name - The name of the Docker image to pull."
    echo "2. tag - The tag of the Docker image."
    echo "3. Emp UD - username used for vault login."
    echo "4. aws_node1, aws_node2, ..... aws_nodeN - The AWS nodes to push the image to."
    exit 1
}

#Chekc if at least 3 arguments are provided (image name, tag, and one AWS node)
if [ "$#" -lt 4 ]; then
   echo "Error: At least three arguments are required."
   usage
fi

#Docker image to pull (passed as the first argument)
DOCKER_REGISTRY=<your-registry-url>
DOCKER_IMAGE=$1
IMAGE_TAG=$2
# EC2 instnace details (passed as the second argument)
EC2_INSTANCES="${@:4}"
#username to login to vault to fetch ssh keys
USERNAME=$3
#Temporary working directory for the tar file
WORK_DIR=/data/PRE/script
# Tar file name (name based on the Docker image)
TAR_FILE="$WORK_DIR/$(echo $IMAGE_TAG | sed 's/\//_/g').tar"
#dest directory
DEST_DIR="/tmp/"
echo -e "\n"
#Fetching Vault signed SSH keys
echo "Fetching Vault signed SSH Key... "
mkdir -p $WORK_DIR/$USERNAME
cd $USERNAME
echo -e "\n"
ssh-keygen -t ed25519 -f "$WORK_DIR/$USERNAME/key" -P ""
#Public Key path..
PUBLIC_KEY_PATH="$WORK_DIR/$USERNAME/key.pub"
echo -e "\n"
echo -e "Public and Private keys are in Place..."
#Defining the values
PRIVATE_KEY_PATH=$WORK_DIR/$USERNAME/key

echo -e "\n"

export VAULT_ADDR=<your-vault-address-url>
vault login -method=ldap username=$USERNAME
vault write MGTI_Devops/ssh/sign/eks-workers public_key=@PUBLIC_KEY_PATH | grep signed_key | sed -e "s/signed_key       //g" > $WORK_DIR/$USERNAME/vault_signed.pub

chmod 600 $WORK_DIR/$USERNAME/vault_signed.pub
PUBLIC_KEY_PATH="$WORK_DIR/$USERNAME/vault_signed.pub"

echo -e "Public and Private keys are successfully fetched from vault..."
# Function to cleanup local temperory files and Docker images
cleanup() {
    echo "Cleaning up local files..."
    rm -rf "$WORK_DIR/$USERNAME"
    rm -rf "$WORK_DIR/$IMAGE_TAG.tar"
    ctr image rm <your-artifactory-url>/$DOKCER_IMAGE:$IMAGE_TAG
}

echo -e "\n"

#Step 2: Pull the Docker image
echo "Pulling Docker image: $DOCKER_IMAGE"
ctr image pull "$DOKCER_REGISTRY/$DOCKER_IMAGE:$IMAGE_TAG"
echo -e "\n"

#Step 3: Save Docker image to tar
echo "Saving Docker image to tar file: $TAR_FILE"
ctr image export "$TAR_FILE" "<REgistry-location-url>/$DOCKER_IMAGE:$IMAGE_TAG"
echo -e "\n"

#Step 4: Loop through EC2 Instances and copy the tar file
for EC2_INSTANCE in "$EC2_INSTANCES;" do
    echo "Copying tar file to EC2 instnace: $EC2_INSTANCE"

    #Use SCP to transfer the tar file to the EC2 instance
    scp -o StrictHostKeyChecking=no -i "$PRIVATE_KEY_PATH" -i "$PUBLIC_KEY_PATH" "$TAR_FILE" ec2-user@"$EC2_INSTANCE:$DEST_DIR"

    if [ $? -ne 0 ]; then
        echo "Failed to copy tar file to $EC2_INSTANCE"
        exit 1
    fi

    #Step 5: Import the Docker image on EC2 instance
    echo "Importing Docker image on EC2 instance: $EC2_INSTANCE"
    ssh -o StrictHostKeyChecking=no -i "$PRIVATE_KEY_PATH" -i "$PUBLIC_KEY_PATH" ec2-user@"$EC2_INSTNACE" "sudo ctr image import /tmp/$IMAGE_TAG.tar"

    if [ $? -ne 0 ]; then
        echo "Failed to load Docker image on EC2 instance: $EC2_INSTANCE"
        exit 1
    fi
done

echo -e "\n"

#Step6: Cleanup local files and Docker images
cleanup

# Success message
echo "Docker image successfully pulled, pushed, imported, and cleaned up."
