---
name: fix-pr
description: Address all PR review comments and CI failures for the current branch
allowed-tools: ["Bash(git:*)", "Bash(gh:*)"]
---

Address every open review comment and failing check on the current branch's PR:

1. Run `gh pr view --json number,url,baseRefName` and `gh pr checks` to list failing checks.

2. Fetch unresolved review threads, including Copilot's:
   ```bash
   gh api graphql -F owner='{owner}' -F repo='{repo}' -F pr=<number> -f query='
     query($owner: String!, $repo: String!, $pr: Int!) {
       repository(owner: $owner, name: $repo) {
         pullRequest(number: $pr) {
           reviewThreads(first: 100) {
             nodes { id isResolved path line
               comments(first: 20) { nodes { author { login } body } } }
           }
         }
       }
     }' --jq '.data.repository.pullRequest.reviewThreads.nodes[] | select(.isResolved | not)'
   ```

3. For each comment: fix it, or explain why not. Then run the full test suite and typecheck for every touched package.

4. For each failing check, compare against the base branch (`gh run list --branch <baseRefName>`) and say which failures are pre-existing.

5. Commit, push, and resolve the addressed threads:
   ```bash
   gh api graphql -F id=<thread id> -f query='
     mutation($id: ID!) { resolveReviewThread(input: {threadId: $id}) { thread { isResolved } } }'
   ```
   Report in at most 5 plain-English bullets.
