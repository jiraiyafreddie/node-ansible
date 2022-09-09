#!/bin/bash

sudo apt update -y
sudo apt install unzip -y
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install


mkdir -p /home/ubuntu/.heimdalld/data/
mkdir -p /home/ubuntu/.bor/data/bor/
BUCKET=snapshot-shibarium-data
OBJECT_bor="$(sudo /usr/local/bin/aws s3 ls $BUCKET/bor/alpha/ --recursive | sort | tail -n 1 | awk '{print $4}')"
sudo /usr/local/bin/aws s3 cp s3://$BUCKET/$OBJECT_bor /tmp/$OBJECT_bor
OBJECT_heimdall="$(sudo /usr/local/bin/aws s3 ls $BUCKET/heimdall/alpha/ --recursive | sort | tail -n 1 | awk '{print $4}')"
sudo /usr/local/bin/aws s3 cp s3://$BUCKET/$OBJECT_heimdall /tmp/$OBJECT_heimdall

tar -xvf /tmp/$OBJECT_heimdall /home/ubuntu/.heimdalld/data/
tar -xvf /tmp/$OBJECT_bor  /home/ubuntu/.bor/data/bor/
