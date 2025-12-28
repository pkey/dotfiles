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
  model="llama3.2"

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
- Subject: max 50 chars, imperative mood (\"add\" not \"added\"), no period
- For small/simple changes: one-line commit only
- For complex changes: add body explaining what/why (wrap lines at 72 chars)
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
