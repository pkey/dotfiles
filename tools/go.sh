_go_version() {
  [[ -f "go.mod" ]] && grep '^go ' go.mod | awk '{print $2}'
}

go() {
  local version=$(_go_version)
  if [[ -n "$version" ]]; then
    local wrapper="$HOME/go/bin/go${version}"
    if [[ ! -x "$wrapper" ]]; then
      echo "Installing Go $version..."
      command go install "golang.org/dl/go${version}@latest"
      "$wrapper" download
    fi
    if [[ -x "$wrapper" ]]; then
      "$wrapper" "$@"
      return
    fi
  fi
  command go "$@"
}

_go_chpwd() {
  local version=$(_go_version)
  if [[ -n "$version" ]]; then
    local wrapper="$HOME/go/bin/go${version}"
    if [[ -x "$wrapper" ]]; then
      echo "Using Go $version (from go.mod)"
    else
      echo "Go $version required (run 'go version' to install)"
    fi
  fi
}
autoload -Uz add-zsh-hook
add-zsh-hook chpwd _go_chpwd
