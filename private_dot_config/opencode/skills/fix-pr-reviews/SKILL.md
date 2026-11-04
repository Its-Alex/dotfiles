---
name: fix-pr-reviews
description: Work through the review comments of one pull request end to end — new OpenChamber session in a new worktree on the PR branch, fix every open thread, resolve the threads that are addressed, rebase on the target branch, push. Use when the user says "fix the review comments on this PR", "adresse les retours de review", "corrige la PR", "traite les commentaires de la PR", "rebase et push la PR", or gives a PR URL/number and asks to get it review-clean.
---

# Fix a PR's review comments

Input: one PR — a number, a URL, or the PR of the current branch (`gh pr view` with no argument).

```bash
PR=$(gh pr view "<number|url>" --json number -q .number)   # normalises a URL to its number
PR_URL=$(gh pr view "$PR" --json url -q .url)
REPO=$(printf '%s' "$PR_URL" | sed -E 's#https://github.com/([^/]+/[^/]+)/pull/.*#\1#')
OWNER=${REPO%/*}; NAME=${REPO#*/}
gh pr view "$PR" --json title,headRefName,baseRefName,isDraft,isCrossRepository,author,headRefOid,mergeable,reviewDecision
```

`REPO` is the base repository (where the review threads live), never the head fork.

If the PR is a draft, say so and ask before touching it. If the head branch is a fork you cannot push to, stop and report.

## 1. New session in a new worktree, on the PR branch

Dispatch with the `openchamber` tool, `session.create`:

- `pullRequest`: the PR number — the session starts in a new worktree on the PR's branch.
- `worktree`: `fix-pr-<number>-reviews`.
- `prompt`: the brief below, with number and URL filled in.
- `returnResult`: `true`, so the outcome comes back here.

```
PR #<number> — <url>. You are already in a worktree on its head branch.

Load the skill `fix-pr-reviews` and execute sections 2 to 6 only (skip section 1).

When done, reply with: every thread id + path:line + what you changed, the
threads you resolved, the rebase result (commits replayed, conflicts), the push
result (old..new sha), and `gh pr checks` state.

When a review point needs my decision — intent, trade-off, a reviewer you
disagree with — ask me in this session and wait. Do not answer for me.
```

Then `session.link` (kind `change`) with the PR URL. Fallback if `pullRequest` is rejected (fork, detached head): `existingBranch: origin/<headRefName>`, `setUpstream: true`.

Everything below runs **inside that session**.

## 2. Collect what is still open

Review threads (the only thing with a resolved state) and their replies:

```bash
gh api graphql -F owner="$OWNER" -F name="$NAME" -F number="$PR" -f query='
query($owner: String!, $name: String!, $number: Int!) {
  repository(owner: $owner, name: $name) {
    pullRequest(number: $number) {
      reviewThreads(first: 100) {
        nodes {
          id isResolved isOutdated path line
          comments(first: 100) { nodes { databaseId author { login } body path line createdAt } }
        }
      }
    }
  }
}' > /tmp/opencode/pr-$PR-threads.json
```

Open work = `isResolved: false`. Also read, because they are not threads and cannot be resolved:

```bash
gh api "repos/$REPO/pulls/$PR/reviews" --paginate    # review bodies (REQUEST_CHANGES / COMMENTED)
gh api "repos/$REPO/issues/$PR/comments" --paginate  # conversation comments
```

Build the list before editing anything: thread id, `path:line`, reviewer, the ask, and what it needs. Print it, and mark every thread that needs a human decision — those are asked at once, before any edit (§3).

## 3. Fix every open thread

Keep commits atomic: one commit = one coherent change, not one per comment, and never a pile of `address review` commits. When the fix belongs to a commit already in the PR, fold it in instead of adding a new one — `git commit --amend --no-edit` if that commit is `HEAD`, otherwise `git commit --fixup=<sha>` (squashed in §5). Conventional commit message, no ticket numbers in code or identifiers — the ticket belongs in the commit message.

Per thread, decide and act:

| Thread says | Do |
| --- | --- |
| Valid, code change needed | Fix it, run the relevant tests/lint. |
| Valid but already fixed by an earlier commit | Verify on `HEAD`, no code change. |
| Outdated (`isOutdated: true`) and no longer applies | Verify against the current diff; resolve with a one-line reason. |
| Question answerable from the code | Answer it in a reply; change code only if the answer exposes a real problem. |
| Question needing the author's intent, or a reviewer you disagree with | Ask in this session (below), park the thread, wait for the answer. |

Never mark a thread resolved without either a code change or an explicit reply saying why nothing changed.

### Ask instead of guessing

A question the code cannot settle — product intent, a trade-off, "why did you do it this way", a reviewer you disagree with — is asked **in this session** and waits for the answer. Do not invent the author's intent, and do not reply on their behalf as if you knew.

- Batch: ask all such questions in one message (thread id, `path:line`, reviewer's words, the options you see) before editing anything, not one message per thread.
- Park the thread: leave it `isResolved: false` with no reply until the user answers. Resolving it first loses the reviewer's objection.
- Then apply the answer and resume at §4.
- Only if the user is unavailable and the fix is unambiguous and reversible, proceed and say which decision you made on their behalf.

## 4. Resolve the threads you addressed

Reply first when the fix is not self-evident (a rename, a moved block, a decision); skip the reply when the diff speaks for itself. Replies and resolutions are GraphQL:

```bash
gh api graphql -F threadId="$THREAD_ID" -F body="$BODY" -f query='
mutation($threadId: ID!, $body: String!) {
  addPullRequestReviewThreadReply(input: {pullRequestReviewThreadId: $threadId, body: $body}) { comment { url } }
}'

gh api graphql -F threadId="$THREAD_ID" -f query='
mutation($threadId: ID!) { resolveReviewThread(input: {threadId: $threadId}) { thread { isResolved } } }'
```

For a review body or a conversation comment, post a normal PR comment with the fix summary — no commit sha: the squash in §5 will invalidate it, the sha belongs in the final summary after the push.

```bash
gh pr comment "$PR" --body "<what changed and where>"
```

Re-run the section 2 query at the end: the only `isResolved: false` left must be the threads you deliberately left open, and each must have your reply.

## 5. Rebase on the target branch

```bash
git fetch origin --prune
BASE=$(gh pr view "$PR" --json baseRefName -q .baseRefName)
GIT_SEQUENCE_EDITOR=true git rebase -i --autosquash "origin/$BASE"
```

`GIT_SEQUENCE_EDITOR=true` accepts the generated todo list as is — the command never blocks on an editor. One command does both jobs: it folds every `--fixup` into its commit and replays the branch onto the target branch.

- Collapse, don't stack: the published history must read as a handful of atomic commits, not as the story of the review. `git log --oneline "origin/$BASE..HEAD"` before and after — the same count as before your fixes is the target when every fix belonged to an existing commit. A fix that is genuinely a new change keeps its own commit.
- Conflicts: resolve, `git add <files>`, `git rebase --continue`. Never `git rebase --skip` on a commit that carries a fix.
- Then re-run the build/tests: a clean rebase is not a working tree.
- Never rewrite a commit authored by someone else on a shared branch — stop and ask first.

## 6. Push

```bash
git log --oneline "origin/$BASE..HEAD"   # what you are about to publish
git push --force-with-lease origin HEAD
```

`--force-with-lease`, never `--force`: it refuses when the remote moved since your last fetch. If it refuses, `git fetch origin`, check who pushed, and ask before retrying. Never disable commit signing to get the push through.

Rewriting already-published commits is expected here: amending and squashing is what keeps the PR from filling up with review-fix commits, and the force push is guarded by the lease. One push at the end, not one per fix.

Then report: `gh pr view "$PR" --json mergeable,reviewDecision` and `gh pr checks "$PR"`. Optionally post one summary comment on the PR with the new head sha and the list of threads addressed, since the force push erased the "changes since your last review" diff.

## Pitfalls

- A rebase on a branch with review comments invalidates the diff anchors: resolve the threads **before** rebasing, so the reviewer sees the fix where they commented.
- `isOutdated` threads often show a stale line; read the current file before deciding they are moot.
- Do not answer on behalf of the author in a way that hides a real objection — a disagreeing reply keeps the thread open.
- One pending review per reviewer per PR: never post your replies as a new review, always as thread replies.
- Both GitHub accounts are wired through `gh`: if the PR lives on a personal repo and `gh` acts as the work account (or the reverse), `gh auth switch --user <account>` — never edit git config or credential helpers.
- Squashing rewrites every sha: never cite a commit sha in a review reply, and expect the reviewer's "viewed" file state to reset after the force push — the per-thread replies are what they read to see what changed.
- A thread you asked about is neither fixed nor resolved: leaving it open with the reviewer's words intact is correct, silently answering it is not.
