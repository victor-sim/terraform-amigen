#!/bin/bash
pwd;
export INSTANCE_ID=$(cat instanceId.txt)
echo "Instance ID is $INSTANCE_ID"
echo "Wait instance ok"
echo "aws ec2 wait instance-status-ok --instance-ids $INSTANCE_ID"
aws ec2 wait instance-status-ok --instance-ids $INSTANCE_ID
echo "Create Image"
echo "aws ec2 create-image --instance-id $INSTANCE_ID --name \"From$INSTANCE_ID\""
export Ami=$(aws ec2 create-image --instance-id $INSTANCE_ID --name "From$INSTANCE_ID")
echo $Ami
export AmiId=$(echo $Ami | python -c "import json,sys;obj=json.load(sys.stdin);print obj['ImageId'];")
echo $Ami > result.json
aws ec2 wait image-available --image-ids $AmiId
echo "Done"
