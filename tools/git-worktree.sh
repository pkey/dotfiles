# git-worktree - minimal helpers for managing git worktrees.
#
# Layout:
#   $GWT_ROOT/<repo>/<branch-slug>
#
# Where:
#   <repo>        = basename of the main repo dir (parent of git-common-dir)
#   <branch-slug> = branch name with '/' replaced by '-'
#
# Manages physical worktrees only. Branch metadata and stacked-PR submission
# stay with Graphite (`gt`).
#
# Usage:
#   gwt                    Show this help
#   gwtn <branch> [base]   Create new worktree from base (default HEAD), then cd
#   gwtc [branch]          Go to <branch>'s worktree (creates one if missing);
#                          no arg = fzf-pick from worktrees + all branches
#   gwtl                   List worktrees for current repo
#   gwtm                   cd to the main worktree ($GWT_MAIN_BRANCH, default 'main')
#   gwtrm                  Remove current worktree (refuses on main); cd to main first
#   gwtrmf                 Same as gwtrm but --force
#   gwtp                   git worktree prune
#
# Config:
#   GWT_ROOT         Root for all worktrees (default: ~/worktrees)
#   GWT_MAIN_BRANCH  Protected main branch name (default: main)

: ${GWT_ROOT:=$HOME/worktrees}
: ${GWT_MAIN_BRANCH:=main}

# --- internal ---------------------------------------------------------------

# Repo name = basename of the main worktree (parent of git-common-dir).
# Works from any worktree of the same repo.
_gwt_repo_name() {
  local common
  common=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || {
    print -u2 "gwt: not inside a git repo"
    return 1
  }
  # ${common:h} = dirname, ${...:t} = basename (zsh modifiers)
  print -r -- "${${common:h}:t}"
}

_gwt_slug() {
  print -r -- "${1//\//-}"
}

# Computed worktree path for a branch (does not check existence).
_gwt_path() {
  local branch=$1 repo
  repo=$(_gwt_repo_name) || return 1
  print -r -- "$GWT_ROOT/$repo/$(_gwt_slug $branch)"
}

# Path of the worktree whose branch is $GWT_MAIN_BRANCH, or fail.
_gwt_main_path() {
  local target="refs/heads/$GWT_MAIN_BRANCH"
  local wt branch line
  while IFS= read -r line; do
    case $line in
      "worktree "*) wt=${line#worktree } ;;
      "branch "*)
        branch=${line#branch }
        if [[ $branch == $target ]]; then
          print -r -- "$wt"
          return 0
        fi
        ;;
    esac
  done < <(git worktree list --porcelain 2>/dev/null)
  return 1
}

# Emit fuzzy-picker candidates: worktrees first, then local-only branches,
# then remote-only branches. Lines are tab-separated:
#   "<display>\t<kind>\t<payload>"
# kind=wt     payload=worktree path
# kind=local  payload=branch name
# kind=remote payload=full remote ref (e.g. origin/feature)
_gwt_candidates() {
  local -A wt_for
  local wt branch line
  while IFS= read -r line; do
    case $line in
      "worktree "*) wt=${line#worktree } ;;
      "branch "*)
        branch=${line#branch refs/heads/}
        wt_for[$branch]=$wt
        ;;
      "") wt=""; branch="" ;;
    esac
  done < <(git worktree list --porcelain)

  local b
  for b in ${(k)wt_for}; do
    print -r -- "[*] $b	wt	${wt_for[$b]}"
  done
  while IFS= read -r b; do
    [[ -n ${wt_for[$b]} ]] && continue
    print -r -- "[ ] $b	local	$b"
  done < <(git for-each-ref --format='%(refname:short)' refs/heads)
  while IFS= read -r b; do
    [[ ${b##*/} == HEAD ]] && continue
    # Skip if a local branch with the same short name already exists.
    git show-ref --verify --quiet "refs/heads/${b#*/}" && continue
    print -r -- "[ ] $b	remote	$b"
  done < <(git for-each-ref --format='%(refname:short)' refs/remotes)
}

# Shared body for gwtrm / gwtrmf.
_gwt_remove_current() {
  local force=$1 cur main
  cur=$(git rev-parse --path-format=absolute --show-toplevel 2>/dev/null) || {
    print -u2 "gwt: not inside a git repo"
    return 1
  }
  main=$(_gwt_main_path) || {
    print -u2 "gwt: cannot locate main worktree (branch '$GWT_MAIN_BRANCH'); refusing to remove"
    return 1
  }
  if [[ $cur == $main ]]; then
    print -u2 "gwt: refusing to remove the main worktree"
    return 1
  fi
  # cd to main first so removing $cur doesn't leave us in a deleted dir.
  cd "$main" || return $?
  if [[ -n $force ]]; then
    git worktree remove --force "$cur"
  else
    git worktree remove "$cur"
  fi
}

# --- public -----------------------------------------------------------------

gwt() {
  cat <<EOF
git-worktree helpers — layout: \$GWT_ROOT/<repo>/<branch-slug>

  gwt                    Show this help
  gwtn <branch> [base]   Create new worktree from base (default HEAD), then cd
  gwtc [branch]          Go to <branch>'s worktree (creates one if missing);
                         no arg = fzf-pick from worktrees + all branches
  gwtl                   List worktrees for current repo
  gwtm                   cd to the main worktree (\$GWT_MAIN_BRANCH)
  gwtrm                  Remove current worktree (refuses on main); cd to main first
  gwtrmf                 Same as gwtrm but --force
  gwtp                   git worktree prune

Config:
  GWT_ROOT=$GWT_ROOT
  GWT_MAIN_BRANCH=$GWT_MAIN_BRANCH
EOF
}

gwtn() {
  local branch=$1 base=${2:-HEAD}
  if [[ -z $branch ]]; then
    print -u2 "usage: gwtn <branch> [base]"
    return 2
  fi
  local wt
  wt=$(_gwt_path $branch) || return 1
  mkdir -p "${wt:h}"
  if git show-ref --verify --quiet "refs/heads/$branch"; then
    # Branch exists; attach a worktree to it. `base` is ignored — git uses
    # the branch tip.
    git worktree add "$wt" "$branch" || return $?
  else
    git worktree add -b "$branch" "$wt" "$base" || return $?
  fi
  cd "$wt"
}

gwtc() {
  local branch=$1 wt
  if [[ -n $branch ]]; then
    wt=$(_gwt_path $branch) || return 1
    if [[ -d $wt ]]; then
      cd "$wt"
      return
    fi
    # No worktree yet — materialize one for the branch.
    if git show-ref --verify --quiet "refs/heads/$branch"; then
      gwtn "$branch"
    elif git show-ref --verify --quiet "refs/remotes/origin/$branch"; then
      gwtn "$branch" "origin/$branch"
    else
      print -u2 "gwt: no worktree or branch named '$branch' (try: gwtn $branch [base])"
      return 1
    fi
    return
  fi

  # Fuzzy mode: pick from worktrees + branches without worktrees.
  if (( ! $+commands[fzf] )); then
    print -u2 "gwt: fzf not found on PATH; pass a branch name instead"
    return 1
  fi
  git rev-parse --git-dir >/dev/null 2>&1 || {
    print -u2 "gwt: not inside a git repo"
    return 1
  }
  local sel kind payload
  sel=$(_gwt_candidates | fzf --height=50% --reverse --with-nth=1 --delimiter=$'\t') || return 130
  # sel is "<display>\t<kind>\t<payload>".
  kind=${${sel#*$'\t'}%%$'\t'*}
  payload=${sel##*$'\t'}
  case $kind in
    wt)     cd "$payload" ;;
    local)  gwtn "$payload" ;;
    # Strip the leading "<remote>/" to get the local branch name.
    remote) gwtn "${payload#*/}" "$payload" ;;
    *)      print -u2 "gwt: unrecognized selection"; return 1 ;;
  esac
}

gwtl() {
  git worktree list
}

gwtm() {
  local wt
  wt=$(_gwt_main_path) || {
    print -u2 "gwt: no worktree on '$GWT_MAIN_BRANCH' found"
    return 1
  }
  cd "$wt"
}

gwtrm()  { _gwt_remove_current "" }
gwtrmf() { _gwt_remove_current "--force" }

gwtp() {
  git worktree prune
}
