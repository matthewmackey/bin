#!/bin/bash

set -e
set -o pipefail

usage() {
  cat <<EOF

$0 <option>

OPTIONS

  -c - Create repo (<repo_name> <project_key>)
  -l - List repos
EOF
  exit 1
}

source ~/.pwd/bitbucket.env

create_repo() {
  PROJECT_KEY=$1
  REPO_NAME=$2

  test -n "$REPO_NAME" || usage
  test -n "$PROJECT_KEY" || usage

  URL="https://api.bitbucket.org/2.0/repositories/$BB_USER_WORKSPACE/$REPO_NAME"

  set -x
  curl -X POST \
    -u "$BB_USER:$BB_APP_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
        "scm": "git",
        "is_private": true,
        "project": {
            "key": "'$PROJECT_KEY'"
        }
      }' \
    "$URL"
  set +x
}

list_repos() {

  URL="https://api.bitbucket.org/2.0/repositories/$BB_USER_WORKSPACE"

  set -x
  curl \
    -u "$BB_USER:$BB_APP_TOKEN" \
    "$URL"  | jq '.values[] | .full_name'
  set +x
}

CMD=""
while getopts ":cl" arg; do
  case "${arg}" in
    c)
      shift
      create_repo $@
      exit
      ;;
    l)
      list_repos
      exit
      ;;
    *)
      usage
      ;;
  esac
done

if [ -z "$CMD" ]; then
  usage
fi
