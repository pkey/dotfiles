_SECRET_SERVICE="env-secret"

secret() {
  local cmd="${1:-}"

  case "$cmd" in
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
    rename)
      shift
      _secret_rename "$@"
      ;;
    update)
      shift
      _secret_update "$@"
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
    export "$name"="$(security find-generic-password -a "$USER" -s "${_SECRET_SERVICE}:${name}" -w)"
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

_secret_update() {
  local name="${1:-}"
  if [[ -z "$name" ]]; then
    name=$(_secret_list | fzf --prompt="Update secret: ")
    [[ -z "$name" ]] && return 1
  fi

  if ! security find-generic-password -a "$USER" -s "${_SECRET_SERVICE}:${name}" -w &>/dev/null; then
    echo "Secret '$name' not found" && return 1
  fi

  printf "New value (hidden): "
  read -rs value
  echo
  [[ -z "$value" ]] && echo "Cancelled" && return 1

  if security add-generic-password -a "$USER" -s "${_SECRET_SERVICE}:${name}" -w "$value" -U 2>/dev/null; then
    export "$name"="$value"
    echo "Secret '$name' updated"
  else
    echo "Failed to update secret" && return 1
  fi
}

_secret_rename() {
  local old_name="${1:-}" new_name="${2:-}"
  if [[ -z "$old_name" ]]; then
    old_name=$(_secret_list | fzf --prompt="Secret to rename: ")
    [[ -z "$old_name" ]] && return 1
  fi

  local value
  value=$(security find-generic-password -a "$USER" -s "${_SECRET_SERVICE}:${old_name}" -w 2>/dev/null)
  if [[ -z "$value" ]]; then
    echo "Secret '$old_name' not found" && return 1
  fi

  if [[ -z "$new_name" ]]; then
    printf "New name: "
    read -r new_name
    [[ -z "$new_name" ]] && echo "Cancelled" && return 1
  fi

  if security find-generic-password -a "$USER" -s "${_SECRET_SERVICE}:${new_name}" -w &>/dev/null; then
    echo "Secret '$new_name' already exists" && return 1
  fi

  security add-generic-password -a "$USER" -s "${_SECRET_SERVICE}:${new_name}" -w "$value" -U 2>/dev/null || { echo "Failed to create renamed secret" && return 1; }
  security delete-generic-password -a "$USER" -s "${_SECRET_SERVICE}:${old_name}" &>/dev/null

  local localzsh="$HOME/.localrc"
  if grep -q "export ${old_name}=" "$localzsh" 2>/dev/null; then
    sed -i '' "s|export ${old_name}=.*|export ${new_name}=\$(security find-generic-password -a \"\$USER\" -s \"${_SECRET_SERVICE}:${new_name}\" -w)|" "$localzsh"
    unset "$old_name"
    export "$new_name"="$value"
    echo "Updated '$old_name' -> '$new_name' in .localrc"
  fi

  echo "Secret renamed: '$old_name' -> '$new_name'"
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
  local localzsh="$HOME/.localrc"

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
  action=$(printf "set\nlist\nget\ndelete\nrename\nupdate\nexport" | fzf --prompt="Secret action: ")
  [[ -z "$action" ]] && return 1
  secret "$action"
}

printenv() {
  local secrets=$(_secret_list)
  [[ -z "$secrets" ]] && command printenv "$@" && return
  local pattern="^(${secrets//$'\n'/|})="
  command printenv "$@" | sed -E "s/${pattern}.*/\1=***REDACTED***/"
}
