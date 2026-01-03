---
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
   - A well-structured body with:
     - **Summary**: Brief description of what this PR does
     - **Changes**: Bullet points of key changes
     - **Testing**: How the changes were tested (if applicable)

4. Use a HEREDOC for the body to ensure proper formatting:
   ```bash
   gh pr create --title "Your title here" --body "$(cat <<'EOF'
   ## Summary
   Brief description here.

   ## Changes
   - Change 1
   - Change 2

   ## Testing
   How it was tested.
   EOF
   )"
   ```

Important:
- Do NOT include any "Co-Authored-By" or "Generated with Claude" footers
- Do NOT include any AI attribution in the PR
- Keep the description professional and focused on the changes
- Return the PR URL when done
