#!/bin/sh
PROFILE=default

# check arguments
if [ $# -lt 1 ]; then
  echo ERROR: The script requires at least one argument.
  exit 1
fi

TEMPLATE=$1-template.yaml
STACK=$1-stack

if [ ! -e templates/${TEMPLATE} ]; then
  echo ERROR: The specified template ${TEMPLATE} does not exist.
  exit 1
fi

# apply template
echo applying ${TEMPLATE} ...

# check if the stack is already created or not
chk=$(aws --profile ${PROFILE} cloudformation list-stacks \
      --stack-status-filter \
        "CREATE_COMPLETE" \
        "UPDATE_COMPLETE" \
        "ROLLBACK_COMPLETE" \
        "UPDATE_ROLLBACK_COMPLETE" \
      | jq -r '.StackSummaries[].StackName' | grep ${STACK} | wc -l)

# create/update stack
if [ 1 -ne ${chk} ]; then
  # create
  echo create-stack ...
  aws --profile ${PROFILE} cloudformation create-stack --stack-name ${STACK} --template-body file://templates/${TEMPLATE} 
else
  # update
  echo update-stack ...
  aws --profile ${PROFILE} cloudformation update-stack --stack-name ${STACK} --template-body file://templates/${TEMPLATE}
fi

if [ $? -eq 0 ]; then
  echo success
  exit 0
else
  exit 1
fi