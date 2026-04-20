# TODO

List is constantly prioritised when adding a new item.

- [ ] full install takes too long (more than 10 minutes)
  - currently getting stuck in the python installation phase
  - actually, gets stuck randmly when upgrading packages. Restartig moves a needle until next failure
  - #1 idea: have base packages.yaml and then separate for each environment (personal vs work)
- [ ] python installed via brew is not actually available
- [ ] figure out history issue in VSCode
- [ ] `fnm` not picked up on linux machine
- [ ] create a minidot for quick setups
- [ ] AI summary of commits is not great for larger changes
- [ ] I need to create an easy way to have common things (aliases, tools, shell functions, etc) and workstation/environment
specific stuff.
- [ ] Create a shared repo (e.g. snyk-dotfiles) for Snyk-specific machine setup: AWS SSO profiles, corp cert bundle, and other org-specific quirks that can be shared with teammates.
See the snyk folder and .localrc for ideas what to migrage.
- [x] Split installation per distro. packages.yaml for macos + Ubuntu
- [ ] Evals for skills
- [ ] Remove packages.yml and use Brewfile + other distro package managers
- [ ] Redo the AGENTS.md and make it super lean
- [ ] Create a mini skills repository that links to external skills in outside github repos (or local skills)

## Mardown Preview

- [ ] Close markdown preview when hx is closed
- [ ] Update active markdown view if different markdown file is opened

## Agentic

- [ ] Hook in autonomous agents that goes through these TODOs and creates PRs for them
