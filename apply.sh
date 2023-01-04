#!/bin/sh
PROFILE=default

# check arguments
if [ $# -lt 1 ]; then
  echo ERROR: The script requires at least one argument.
  exit 1
fi

TEMPLATE=$1-template.yaml
PARAMS=$1-parameters.json
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
alias create-stack="aws --profile ${PROFILE} cloudformation create-stack --stack-name ${STACK} --template-body file://templates/${TEMPLATE} --capabilities CAPABILITY_IAM"
alias update-stack="aws --profile ${PROFILE} cloudformation update-stack --stack-name ${STACK} --template-body file://templates/${TEMPLATE} --capabilities CAPABILITY_IAM"
if [ 1 -ne ${chk} ]; then
  # create
  echo create-stack ...
  if [ -e parameters/${PARAMS} ]; then
    MINIFIED_PARAMS=$(jq -c < parameters/${PARAMS})
    create-stack --parameters "${MINIFIED_PARAMS}"
  else
    create-stack
  fi
else
  # update
  echo update-stack ...
  if [ -e parameters/${PARAMS} ]; then
    MINIFIED_PARAMS=$(jq -c < parameters/${PARAMS})
    update-stack --parameters "${MINIFIED_PARAMS}"
  else
    update-stack
  fi
fi

# check exit code
if [ $? -eq 0 ]; then
  echo success
  exit 0
else
  exit 1
fi