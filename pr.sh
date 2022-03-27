#!/usr/bin/env bash

### 定期的にmainへのPRを作成する

set -e
set -o pipefail

if [[ -z "$GITHUB_TOKEN" ]]; then
  echo "tokenの指定がないので失敗しています。env.GITHUB_TOKENを指定してください。"
  exit 1
fi

if [[ -z "$SOURCE_BRANCH" ]]; then
  echo "ブランチの指定がないので失敗しています env.SOURCE_BRANCHを指定してください"
  exit 1
fi
if [[ -z "$GITHUB_ACTOR" ]]; then
  echo "ユーザの指定がないので失敗しています env.GITHUB_ACTORを指定してください"
  exit 1
fi
if [[ -z "$GITHUB_SERVER_URL" ]]; then
  echo "サーバの指定がないので失敗しています env.GITHUB_SERVER_URLを指定してください"
  exit 1
fi
if [[ -z "$GITHUB_REPOSITORY" ]]; then
  echo "レポジトリの指定がないので失敗しています env.GITHUB_REPOSITORYを指定してください"
  exit 1
fi

git remote set-url origin "https://$GITHUB_ACTOR:$GITHUB_TOKEN@${GITHUB_SERVER_URL#https://}/$GITHUB_REPOSITORY"
git fetch origin '+refs/heads/*:refs/heads/*' --update-head-ok
git --no-pager branch -a -vv

## revが同じなら終了
if [ "$(git rev-parse --revs-only "$SOURCE_BRANCH")" = "$(git rev-parse --revs-only main)" ]; then
  echo "Source and destination branches are the same."
  exit 0
fi

PR_ARG="$INPUT_PR_TITLE"
if [[ ! -z "$PR_ARG" ]]; then
  PR_ARG="-m \"$PR_ARG\""

  if [[ ! -z "$INPUT_PR_TEMPLATE" ]]; then
    sed -i 's/`/\\`/g; s/\$/\\\$/g' "$INPUT_PR_TEMPLATE"
    PR_ARG="$PR_ARG -m \"$(echo -e "$(cat "$INPUT_PR_TEMPLATE")")\""
  elif [[ ! -z "$INPUT_PR_BODY" ]]; then
    PR_ARG="$PR_ARG -m \"$INPUT_PR_BODY\""
  fi
fi

if [[ ! -z "$INPUT_PR_REVIEWER" ]]; then
  PR_ARG="$PR_ARG -r \"$INPUT_PR_REVIEWER\""
fi

if [[ ! -z "$INPUT_PR_ASSIGNEE" ]]; then
  PR_ARG="$PR_ARG -a \"$INPUT_PR_ASSIGNEE\""
fi

if [[ ! -z "$INPUT_PR_LABEL" ]]; then
  PR_ARG="$PR_ARG -l \"$INPUT_PR_LABEL\""
fi

if [[ ! -z "$INPUT_PR_MILESTONE" ]]; then
  PR_ARG="$PR_ARG -M \"$INPUT_PR_MILESTONE\""
fi

if [[ "$INPUT_PR_DRAFT" == "true" ]]; then
  PR_ARG="$PR_ARG -d"
fi

COMMAND="hub pull-request -b main -h dev --no-edit $PR_ARG || true"
PR_URL=$(sh -c "$COMMAND")
if [[ "$?" != "0" ]]; then
  exit 1
fi

echo "$COMMAND"
echo ${PR_URL}
echo "::set-output name=pr_url::${PR_URL}"
echo "::set-output name=pr_number::${PR_URL##*/}"

if [[ "$LINES_CHANGED" = "0" ]]; then
  echo "::set-output name=has_changed_files::false"
  echo "::set-output name=SELECTED_COLOR::green"
else
  echo "::set-output name=has_changed_files::true"
  echo "::set-output name=SELECTED_COLOR::red"
fi

export CURRENT_DATETIME=$(date +'%Y%m%d%H%M%S')
git config --global user.name '${GITHUB_ACTOR}'
git config --global user.email '${GITHUB_ACTOR}@users.noreply.github.com'
git switch -c release/release_$CURRENT_DATETIME
git add -A && git commit -m 'abc' --allow-empty
git push origin release/release_$CURRENT_DATETIME
