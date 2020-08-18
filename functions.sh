#Functions
#--Git

git_current_branch () {
    if ! git rev-parse 2> /dev/null
    then
        print "$0: not a repository: $PWD" >&2
        return 1
    fi
    local ref="$(git symbolic-ref HEAD 2> /dev/null)"
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
  local repo="pwd | perl -pe 's#.+github.com/##'"

  curl \
      -XPUT \
      -H "Authorization: token $GITHUB_TOKEN" \
      https://api.github.com/repos/$repo/pulls/$argv[1]/merge
}
