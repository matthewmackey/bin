#!/bin/bash

set -e
set -o pipefail

usage() {
  cat <<EOF

$0 <option>

OPTIONS

  -c - Create repo (<project_key> <repo_name>)
  -l - List repos
EOF
  exit 1
}

source ~/.pwd/bitbucket.env

create_repo() {
  PROJECT_KEY=$1
  REPO_NAME=$2

  test -n "$PROJECT_KEY" || usage
  test -n "$REPO_NAME" || usage

  URL="https://api.bitbucket.org/2.0/repositories/$BB_USER_WORKSPACE/$REPO_NAME"

  RESP=$(curl -X POST \
    "$URL" \
    -s \
    -u "$BB_USER:$BB_APP_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
        "scm": "git",
        "is_private": true,
        "project": {
            "key": "'$PROJECT_KEY'"
        }
      }' 2>/dev/null
    )
    if echo $RESP | grep -q '"type": "error"'; then
      printf "[ERROR]\n\n"
      printf "$RESP"
      return 1
    else
      SSH_CLONE_URL=$(echo "$RESP" | jq -r '.links.clone | .[] | select(.name == "ssh").href')
      CLONE_CMD="git clone $SSH_CLONE_URL"
      ADD_REMOTE_CMD="git remote add origin $SSH_CLONE_URL"
      printf "Repo created"
      printf "Clone the repo with:\n"
      printf "  $CLONE_CMD\n\n"

      printf "Add as remote with:\n"
      printf "  $ADD_REMOTE_CMD\n\n"

      if which xclip >&/dev/null; then
        printf "Add remote command sent to clipboard\n"
        printf "$ADD_REMOTE_CMD" | xclip -sel clip
      fi
    fi
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
