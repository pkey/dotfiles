#Functions
#--Git

git_current_branch () {
    if ! git rev-parse 2> /dev/null
    then
        print "$0: not a repository: $PWD" >&2
        return 1
    fi
    local ref
    ref="$(git symbolic-ref HEAD 2> /dev/null)"
    if [[ -n "$ref" ]]
    then
        print "${ref#refs/heads/}"
        return 0
    else
        return 1
    fi
}

byebranch () {
  git push -d origin "$@" || git branch -d "$@"
}

merge () {
  local repo
  repo="$(pwd | perl -pe 's#.+github.com/##')"

  curl \
      -XPUT \
      -H "Authorization: token $GITHUB_TOKEN" \
      https://api.github.com/repos/"$repo"/pulls/"${argv[1]}"/merge
}

findUnpushedCommits () {
  find ./ -type d -maxdepth 3 -exec sh -c 'cd "$1" && git cherry -v' _ {} \;
}

#TODO: allow dynamic prompt (based on environment)
#TODO: allow using models beyond local ollama
aicommit () {
  model="qwen2.5-coder"

  # Check if there are staged changes
  if ! git diff --cached --quiet; then
    echo "Generating commit message from staged changes using $model..."

    # Get the diff of staged changes
    local diff_output
    diff_output=$(git diff --cached)

    # Create prompt for commit message generation
    local prompt="You are a git commit message generator. Analyze the provided git diff and generate a conventional commit message following this format:

<type>: <subject>

[optional body]

Guidelines:
- Types: feat, fix, docs, style, refactor, test, chore, perf
- ALWAYS follow the format exactly, do not deviate from it
- Subject: max 50 chars, imperative mood (\"add\" not \"added\"), no period
- For small/simple changes: one-line commit only
- For complex changes: add body explaining what/why (wrap lines at 72 chars and keep the total amount to two paragraphs at most)
- Body should provide context, rationale, or additional details not obvious from the diff
- Separate subject from body with a blank line
- Only output the commit message, nothing else

Git diff:
$diff_output"

    # Generate commit message using ollama
    local commit_msg
    commit_msg=$(echo "$prompt" | ollama run "$model" 2>/dev/null)

    if [[ -n "$commit_msg" ]]; then
      # Commit with the generated message (opens editor for review)
      git commit -e -m "$commit_msg"
    else
      echo "Failed to generate commit message. Make sure ollama is running and model '$model' is available."
      return 1
    fi
  else
    echo "No staged changes to commit"
    return 1
  fi
}

#--Secrets (macOS Keychain)
# Manage environment variable secrets stored in macOS keychain
# Usage: secret <command> [args]
#   set     - Add secret to keychain and local.zsh
#   add     - Add a new secret (interactive)
#   list    - List all secret names
#   get     - Get a secret value
#   delete  - Delete a secret
#   export  - Add secret to local.zsh for auto-export
#   (no args) - Interactive mode with fzf

_SECRET_SERVICE="env-secret"

secret() {
  local cmd="${1:-}"

  case "$cmd" in
    add)
      _secret_add
      ;;
    list)
      _secret_list
      ;;
    get)
      shift
      _secret_get "$@"
      ;;
    delete)
      shift
      _secret_delete "$@"
      ;;
    export)
      shift
      _secret_export "$@"
      ;;
    set)
      _secret_set
      ;;
    *)
      _secret_interactive
      ;;
  esac
}

_secret_add() {
  printf "Environment variable name: "
  read -r name
  [[ -z "$name" ]] && echo "Cancelled" && return 1

  printf "Value (hidden): "
  read -rs value
  echo
  [[ -z "$value" ]] && echo "Cancelled" && return 1

  if security add-generic-password -a "$USER" -s "${_SECRET_SERVICE}:${name}" -w "$value" -U 2>/dev/null; then
    echo "Secret '$name' saved"
  else
    echo "Failed to save secret" && return 1
  fi
}

_secret_set() {
  printf "Environment variable name: "
  read -r name
  [[ -z "$name" ]] && echo "Cancelled" && return 1

  printf "Value (hidden): "
  read -rs value
  echo
  [[ -z "$value" ]] && echo "Cancelled" && return 1

  if security add-generic-password -a "$USER" -s "${_SECRET_SERVICE}:${name}" -w "$value" -U 2>/dev/null; then
    _secret_export "$name"
    export "$name"=$(security find-generic-password -a "$USER" -s "${_SECRET_SERVICE}:${name}" -w)
  else
    echo "Failed to save secret" && return 1
  fi
}

_secret_list() {
  security dump-keychain 2>/dev/null | grep "\"svce\".*${_SECRET_SERVICE}:" | sed 's/.*"\(env-secret:[^"]*\)".*/\1/' | cut -d: -f2 | sort -u
}

_secret_get() {
  local name="${1:-}"
  if [[ -z "$name" ]]; then
    name=$(_secret_list | fzf --prompt="Select secret: ")
    [[ -z "$name" ]] && return 1
  fi
  security find-generic-password -a "$USER" -s "${_SECRET_SERVICE}:${name}" -w 2>/dev/null
}

_secret_delete() {
  local name="${1:-}"
  if [[ -z "$name" ]]; then
    name=$(_secret_list | fzf --prompt="Delete secret: ")
    [[ -z "$name" ]] && return 1
  fi
  if security delete-generic-password -a "$USER" -s "${_SECRET_SERVICE}:${name}" 2>/dev/null; then
    echo "Secret '$name' deleted"
  else
    echo "Secret not found" && return 1
  fi
}

_secret_export() {
  local name="${1:-}"
  if [[ -z "$name" ]]; then
    name=$(_secret_list | fzf --prompt="Export secret: ")
    [[ -z "$name" ]] && return 1
  fi
  # Verify secret exists
  if ! security find-generic-password -a "$USER" -s "${_SECRET_SERVICE}:${name}" -w &>/dev/null; then
    echo "Secret not found" && return 1
  fi
  local export_line="export ${name}=\$(security find-generic-password -a \"\$USER\" -s \"${_SECRET_SERVICE}:${name}\" -w)"
  local localzsh="${DOTFILES:-$HOME/dotfiles}/zsh/local.zsh"

  # Check if already exported
  if grep -q "export ${name}=" "$localzsh" 2>/dev/null; then
    echo "'$name' already in local.zsh"
    return 0
  fi

  echo "$export_line" >> "$localzsh"
  echo "Added '$name' to local.zsh"
}

_secret_interactive() {
  local action
  action=$(printf "set\nadd\nlist\nget\ndelete\nexport" | fzf --prompt="Secret action: ")
  [[ -z "$action" ]] && return 1
  secret "$action"
}

printenv() {
  local secrets=$(_secret_list)
  [[ -z "$secrets" ]] && command printenv "$@" && return
  local pattern="^(${secrets//$'\n'/|})="
  command printenv "$@" | sed -E "s/${pattern}.*/\1=***REDACTED***/"
}
