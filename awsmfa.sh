#!/bin/bash

#-------------------------------------------------------------------------------
# See:
#  - https://aws.amazon.com/premiumsupport/knowledge-center/authenticate-mfa-cli/
#  - https://github.com/broamski/aws-mfa
#-------------------------------------------------------------------------------

usage() {
  CMD=$(basename $0)

  cat <<EOF

NAME

  $CMD - generate AWS CLI credentials file for profile requiring MFA

SYNOPSIS

  $CMD PROFILE_NAME MFA_CODE [REGION]

DESCRIPTION

  REGION   AWS region to set for MFA profile that this script creates (Default: $DEFAULT_REGION)

EOF
}

resetAwsCredsFile() {
  # Idempotently reset AWS credentials file to profile's credentials file
  if [ -e $AWS_CREDS ]; then
    if [ -L $AWS_CREDS ]; then
      echo "Removing symlink at: $AWS_CREDS"
      rm $AWS_CREDS
    else
      echo "Warning: $AWS_CREDS exists and is not a symlink."
      echo "Making a backup at: $AWS_CREDS_BACKUP"
      cp $AWS_CREDS $AWS_CREDS_BACKUP
    fi
  fi

  cp $PROFILE_CREDS $AWS_CREDS
  echo "Copied: $AWS_CREDS -> $PROFILE_CREDS"
}

getMfaSerialNumberForProfile() {
  MFA_SERIAL_NUMBER=$(cat $PROFILE_CREDS | grep 'mfa_serial' | awk '{ print $3; }')
  if [ -z "$MFA_SERIAL_NUMBER" ]; then
    echo "No 'mfa_serial' key exists in profile credentials file at: $PROFILE_CREDS"
    usage
    exit 1
  else
    echo "Using MFA serial number: $MFA_SERIAL_NUMBER"
  fi
}

getSessionTokenForProfile() {
  TOKEN_DURATION_SECONDS=$((60*60*$TOKEN_DURATION_HOURS))
  SESSION_TOKEN_CMD="aws sts get-session-token \
    --serial-number $MFA_SERIAL_NUMBER \
    --token-code $MFA_CODE \
    --profile $PROFILE \
    --duration-seconds $TOKEN_DURATION_SECONDS"

  echo
  echo "Running command: $SESSION_TOKEN_CMD"

  SESSION_TOKEN_OUT=$(eval $SESSION_TOKEN_CMD)

  if [ $? != 0 ]; then
    echo "Error running 'aws sts get-session-token' command"
    exit 1
  fi

  EXPIRATION=$(echo $SESSION_TOKEN_OUT | jq -r '.Credentials.Expiration')

  echo
  echo "Token expires in: $TOKEN_DURATION_HOURS hours"
  echo "Token expires at: $EXPIRATION"
}

updateCredsFileWithToken() {
  echo
  cat >> $AWS_CREDS <<EOF

[$PROFILE-mfa]
$(echo $SESSION_TOKEN_OUT | jq -r -f $JQ_SESSION_TOKEN_FILTER)
region = $REGION
EOF

}

#-------------------------------------------------------------------------------
# MAIN
#-------------------------------------------------------------------------------
SCRIPT_DIR=$(cd $(dirname $0); pwd)

AWS_CREDS=~/.aws/credentials
AWS_CREDS_BACKUP=~/.aws/credentials.bak
DEFAULT_REGION=us-east-1
JQ_SESSION_TOKEN_FILTER=$SCRIPT_DIR/jq/aws-convertSessionTokenJsonToIniCreds.jq
PROFILE_BASE_DIR=~/crypt/aws
TOKEN_DURATION_HOURS=8

PROFILE=$1
MFA_CODE=$2
REGION=${3:-$DEFAULT_REGION}

if [ -z "$PROFILE" -o -z "$MFA_CODE" ]; then
  usage
  exit 1
fi

echo "Using region: $REGION"

PROFILE_CREDS=$PROFILE_BASE_DIR/credentials.$PROFILE
if [ ! -f $PROFILE_CREDS ]; then
  echo "No credentials file for profile '$PROFILE' exists at: $PROFILE_CREDS"
  usage
  exit 1
else
  echo "Using creds file at: $PROFILE_CREDS"
fi

resetAwsCredsFile
getMfaSerialNumberForProfile
getSessionTokenForProfile
updateCredsFileWithToken

echo
cat $AWS_CREDS
