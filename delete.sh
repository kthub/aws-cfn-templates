#!/bin/sh
PROFILE=default
REGION=ap-northeast-1

# check arguments
if [ $# -lt 1 ]; then
  echo ERROR: The script requires at least one argument.
  exit 1
fi

STACK=$1-stack

# delete template
echo deleting ${STACK} ...

# check if the stack exists or not
chk=$(aws --profile ${PROFILE} --region ${REGION} cloudformation list-stacks \
      --stack-status-filter \
        "CREATE_COMPLETE" \
        "UPDATE_COMPLETE" \
        "ROLLBACK_COMPLETE" \
        "UPDATE_ROLLBACK_COMPLETE" \
      | jq -r '.StackSummaries[].StackName' | grep ${STACK} | wc -l)

# delete stack
if [ 1 -ne ${chk} ]; then
  echo ERROR: ${STACK} does not exist.
else
  # delete
  echo delete-stack ...
  aws --profile ${PROFILE} --region ${REGION} cloudformation delete-stack --stack-name ${STACK}
fi

# check exit code
if [ $? -eq 0 ]; then
  echo success
  exit 0
else
  exit 1
fi