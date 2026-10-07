---
name: review-open-prs
description: Review every open PR where the user's review is requested, one isolated git worktree per PR, and leave the findings as pending Conventional Comments the user validates on GitHub. Use when the user asks to review their pending review requests, "review all my PRs", "lance les reviews", "passe sur mes PRs à reviewer", or gives a GitHub pulls URL with `user-review-requested:@me`.
---

# Review all PRs awaiting my review

Default repository: `RELEX-Solutions/store-operations-monorepo`. Use another one only if the user names it.

## 1. List the PRs

```bash
gh pr list -R RELEX-Solutions/store-operations-monorepo \
  --search "is:pr is:open user-review-requested:@me" \
  --json number,title,url,headRefName,isDraft,author
```

Print the list (number, title, author) before dispatching. Skip nothing silently; if a PR is a draft, say so and ask whether to include it.

## 2. One worktree per PR

Spawn one subagent per PR, all in parallel in a single message, each with `isolation: worktree` so it gets its own git worktree (the same isolation Claude Desktop gives every Code session). Give each subagent the full per-PR brief from section 3 with the PR number and URL filled in: it knows nothing about this conversation.

When the user prefers separate Claude Desktop sessions instead, give them the per-PR brief for each PR and let them start one session per PR (Desktop creates a worktree for each).

## 3. Per-PR brief (what each agent does)

1. `gh pr checkout <number>` inside the worktree, then review the PR with `/code-review <number>` (never with `--comment`, which posts immediately instead of leaving a pending review) and read the touched files in full where the findings need more context.
2. Turn every finding into its own comment, following the rules below.
3. Post them all as one **pending** review. Never submit it.
4. Reply with the list of comments posted (path:line + label + subject) and the PR URL.

## 4. Comment rules

**Conventional Comments, label written in full and in bold, at the very start of the comment:**

```
**issue (blocking):** <subject>

<discussion: why it matters, evidence, suggested fix>
```

Labels: `praise`, `nitpick`, `suggestion`, `issue`, `todo`, `question`, `thought`, `chore`, `note`, `typo`, `polish`, `quibble`. Optional decorations in parentheses: `(blocking)`, `(non-blocking)`, `(if-minor)`. Spell the label out: never abbreviate or replace it by an emoji.

**One comment = one problem.** Never bundle two findings, even on the same line or in the same file. If in doubt, split.

**Anchor on lines whenever possible.** Use an inline comment on the exact line (or line range) of the diff. If the finding is about the file but no diff line fits, use a file-level comment. Only when it is truly about the PR as a whole (missing tests, design, scope), put it in the pending review body, as its own numbered item with its own bold label.

**Pending only.** The user reviews on GitHub and submits or discards. Never pass `event` (`APPROVE`, `COMMENT`, `REQUEST_CHANGES`) and never submit.

## 5. Posting a pending review

Creating a review without `event` leaves it pending. Send every inline comment in a single call:

```bash
gh api -X POST repos/{owner}/{repo}/pulls/<number>/reviews --input - <<'JSON'
{
  "commit_id": "<head sha from gh pr view --json headRefOid>",
  "body": "",
  "comments": [
    { "path": "src/a.py", "line": 42, "side": "RIGHT", "body": "**issue (blocking):** ..." },
    { "path": "src/b.py", "start_line": 10, "line": 14, "side": "RIGHT", "body": "**suggestion:** ..." },
    { "path": "src/c.py", "subject_type": "file", "body": "**question:** ..." }
  ]
}
JSON
```

- `line` must be a line present in the diff, on the `RIGHT` side for added or context lines and `LEFT` for removed ones; otherwise the API returns 422. Re-check against `gh pr diff` and fall back to a file-level comment.
- GitHub allows a single pending review per user per PR. If one already exists (`gh api repos/{owner}/{repo}/pulls/<number>/reviews`, state `PENDING`), add to it with the GraphQL `addPullRequestReviewThread` mutation (`pullRequestReviewId`, `path`, `line`, `body`) instead of creating another.
- Verify afterwards that the review is `PENDING` and the comment count matches.
