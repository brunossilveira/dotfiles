---
name: open-pr
description: Push current branch and open a PR with a generated description
allowed-tools: ["Bash(git:*)", "Bash(gh:*)"]
---

Create a pull request for the current branch by following these steps:

1. First, gather context by running these commands:
   - `git status` to check the current state
   - `git branch --show-current` to get the current branch name
   - `git log main..HEAD --oneline` (or master..HEAD) to see commits on this branch
   - `git diff main..HEAD` (or master..HEAD) to see all changes

2. Push the current branch to origin:
   ```bash
   git push -u origin HEAD
   ```

3. Create the PR using `gh pr create` with:
   - A clear, concise title summarizing the changes
   - A short body for a reviewer who has the diff, dropping any section with nothing to say:
     - **Why**: The problem and approach, in 1-3 sentences
     - **What changed**: 1-3 bullets
     - **Scope**: What it covers and what it deliberately leaves out
     - **Blast radius**: Who or what it touches, and why that is safe or risky
     - **Verification**: Each real run and its outcome

4. Use a HEREDOC for the body to ensure proper formatting:
   ```bash
   gh pr create --title "Your title here" --body "$(cat <<'EOF'
   ## Why
   The problem and approach.

   ## What changed
   - Change 1

   ## Scope
   - Covers X. Leaves out Y.

   ## Blast radius
   What it touches and why that is safe.

   ## Verification
   - The command or flow that ran, and its outcome.
   EOF
   )"
   ```

Important:
- Do NOT include any "Co-Authored-By" or AI-generation footers
- Do NOT include any AI attribution in the PR
- Keep the description professional and focused on the changes
- Return the PR URL when done
