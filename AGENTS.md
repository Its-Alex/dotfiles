# AGENTS.md

This file is ignored by chezmoi (see `.chezmoiignore`) and therefore never deployed to the target system.

## Mandatory rule for any LLM/agent

This repository is the **chezmoi** source repository for dotfiles. Any configuration change made here must **never** be applied directly to the system by an LLM/agent.

- The LLM/agent may modify files in this repository (propose changes, fix issues, commit if explicitly requested).
- The LLM/agent must **never** run `chezmoi apply`, `chezmoi update`, or any other command that applies changes to the system.
- Applying changes (`chezmoi apply`) must **always** be done manually by the user, after reviewing the modifications.

In summary: the LLM modifies the repo, the user applies changes manually via `chezmoi apply`.
