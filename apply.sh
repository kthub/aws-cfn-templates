#!/bin/bash
set -e

##
## Constants
##
readonly PROFILE=default
readonly REGION=ap-northeast-1

if [ $# -lt 1 ]; then
  echo ERROR: The script requires at least one argument.
  exit 1
fi

readonly TEMPLATE=$1-template.yaml
readonly PARAMS=$1-parameters.json
readonly STACK=$1-stack

if [ ! -e templates/${TEMPLATE} ]; then
  echo ERROR: The specified template ${TEMPLATE} does not exist.
  exit 1
fi

##
## Apply template
##
echo applying ${TEMPLATE} ...

# check if the stack is already created or not
chk=$(aws --profile ${PROFILE} --region ${REGION} cloudformation list-stacks \
      --stack-status-filter \
        "CREATE_COMPLETE" \
        "UPDATE_COMPLETE" \
        "ROLLBACK_COMPLETE" \
        "UPDATE_ROLLBACK_COMPLETE" \
      | jq -r '.StackSummaries[].StackName' | grep ${STACK} | wc -l)

# create/update stack
create-stack() {
  aws --profile ${PROFILE} --region ${REGION} cloudformation create-stack --stack-name ${STACK} --template-body file://templates/${TEMPLATE} --capabilities CAPABILITY_IAM $@
}
update-stack() {
  aws --profile ${PROFILE} --region ${REGION} cloudformation update-stack --stack-name ${STACK} --template-body file://templates/${TEMPLATE} --capabilities CAPABILITY_IAM $@
}

if [ 1 -ne ${chk} ]; then
  # create
  echo request create-stack ...
  if [ -e parameters/${PARAMS} ]; then
    MINIFIED_PARAMS=$(jq -c < parameters/${PARAMS})
    create-stack --parameters "${MINIFIED_PARAMS}"
  else
    create-stack
  fi
else
  # update
  echo request update-stack ...
  if [ -e parameters/${PARAMS} ]; then
    MINIFIED_PARAMS=$(jq -c < parameters/${PARAMS})
    update-stack --parameters "${MINIFIED_PARAMS}"
  else
    update-stack
  fi
fi

echo The request was successfully sent.