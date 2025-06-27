# Work-specific tweaks
export AIDER_MODEL="gemini/gemini-2.5-pro"

# TODO: potentially improve to use op run
aider() {
  export GEMINI_API_KEY=$(op read "op://Employee/Gemini API Key/credential")
  command aider "$@"
}
