#########
# Enable
#########
#!/bin/bash
# Enable termination protection

set -x
# Purpose: To protect all my existing resources from accidental termination

REGION="us-east-1"
INSTANCE_ID=$(aws ec2 describe-instances --output text --query 'Reservations[*].Instances[*].InstanceId' --region $REGION)

export REGION
export INSTANCE_ID

for ec2 in $INSTANCE_ID
do
  echo "protecting ec2 in region $REGION"
  aws ec2 modify-instance-attribute --disable-api-termination --instance-id $ec2
done

#########
# Disable
#########
------------------------------------------------------------------------------------------------------------------------------------------

#!/bin/bash
# Disable termination protection

set -x
# Purpose: To protect all my existing resources from accidental termination

REGION="us-east-1"
INSTANCE_ID=$(aws ec2 describe-instances --output text --query 'Reservations[*].Instances[*].InstanceId' --region $REGION)

export REGION
export INSTANCE_ID

for ec2 in $INSTANCE_ID
do
  echo "protecting ec2 in region $REGION"
  aws ec2 modify-instance-attribute --no-disable-api-termination --instance-id $ec2
done
