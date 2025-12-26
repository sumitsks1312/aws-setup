#!/bin/bash
set -e

ROLE_NAME=$1
PROFILE_NAME=$2

# Create instance profile if not exists
if aws iam get-instance-profile \
  --instance-profile-name "$PROFILE_NAME" >/dev/null 2>&1; then
  echo "Instance Profile '$PROFILE_NAME' already exists"
else
  aws iam create-instance-profile \
    --instance-profile-name "$PROFILE_NAME" \
    >/dev/null
  echo "Created Instance Profile '$PROFILE_NAME'"
fi

# Check if role already attached
ATTACHED_ROLE=$(aws iam get-instance-profile \
  --instance-profile-name "$PROFILE_NAME" \
  --query 'InstanceProfile.Roles[0].RoleName' \
  --output text)

if [ "$ATTACHED_ROLE" = "$ROLE_NAME" ]; then
  echo "Role '$ROLE_NAME' already attached to '$PROFILE_NAME'"
elif [ "$ATTACHED_ROLE" = "None" ]; then
  aws iam add-role-to-instance-profile \
    --instance-profile-name "$PROFILE_NAME" \
    --role-name "$ROLE_NAME"
  echo "Attached Role '$ROLE_NAME' to '$PROFILE_NAME'"
  sleep 10  # Wait for a few seconds to allow IAM changes to propagate
else
  echo "ERROR: Instance profile already has role '$ATTACHED_ROLE'"
  exit 1
fi

echo "Instance Profile '$PROFILE_NAME' with Role '$ROLE_NAME' is ready"
