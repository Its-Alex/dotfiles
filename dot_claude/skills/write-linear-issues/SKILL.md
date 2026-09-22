---
name: write-linear-issues
description: Write or revise Linear issues that a reader can verify without trusting the author — correct section anatomy, dependency-encoding Todos, every claim backed by a reproducible command, every path and URL checked, every mention hyperlinked. Use when drafting a milestone's issues, rewriting a ticket, or adding links to existing tickets. Triggers on "write the issues", "draft the tickets", "update the ticket", "add links", "milestone", "technical backlog", "rédige les issues", "écris les tickets", "ajoute des liens".
---

# Writing verifiable Linear issues

An issue is worth something only if a reader can check every claim in it without
trusting whoever wrote it. Everything below serves that.

## 1. Anatomy — the sections, and what each must contain

```
# Contexte
# Requirements   (only when there is something real to require)
# Todo           (step-by-step, each item a checkbox)
**Done when:**   (one closing line)
```

Nothing goes before `# Contexte`. No preamble, no restating the title.

`# Contexte` is not a summary. It must cover, in whatever order reads best:

- **the problem or the need** — what is actually wrong or missing
- **the impact and the pain** — who suffers, and how it shows up
- **the before / after** — the concrete state today, and the concrete state once
  this is done
- **the possible solutions** — the options considered, and why one is favoured.
  Where a real choice remains open, say so instead of hiding it.

`**Done when:**` states an observable outcome, not an activity. "A PR declares a
workspace and it appears in Terraform Cloud", not "the workspace is set up".

## 2. Todo — nesting IS the dependency graph

This is load-bearing and easy to treat as decoration.

- List sub-issues **in the order they must be completed**.
- A task nested under another is a **subtask**, which implies a dependency and
  therefore probably a **blocking** relationship.
- Tasks at the **same level** can be done **in parallel**.

Markdown nesting only expresses one parent. When a task is blocked by two
things, nest it under one and **name the second blocker in the line's text** —
otherwise the second dependency is invisible.

When the issues exist in Linear, mirror this in the real `blocks` / `blockedBy`
relations. The written tree and the relation graph must agree; a reader trusting
one over the other will sequence the work wrong.

## 3. Writing register

- **Issues are written in French.** Titles are English and use **plain natural
  language** — never Conventional Commits (`feat:`, `fix(scope):`).
- Keep **English technical terms** rather than translating them. `workspace`,
  `state`, `plan`, `backend` stay as they are.
- **Mirror the user's own shapes**: if the request came as a bullet list, answer
  in bullet lists.
- Be **explicit**. Repeating a pronoun or a noun to remove ambiguity is better
  than an elegant sentence the reader has to re-parse.
- **Keep epistemic hedging markers** — "probably", "à confirmer", "il semble
  que". Add them where they carry information; leave them out where they only
  soften. A hedge that marks a real unknown is a fact about the state of
  knowledge.
- **Keep WikiLinks** (`[[…]]`) and **keep hashtags** if they are present in the
  source material.
- **Never a marketing register.** Direct, relaxed professional. The measured
  fact, the named trap, then stop — no closing paragraph restating what was just
  read.
- Concise, but keep the context that is actually required.

### Formatting: no linter, deliberately

The description must **not** be run through markdown linting conventions:

- **No hard wrapping at 80 characters.** Write prose freely; let it flow.
- **No formatter-style line breaks mid-sentence.**
- Markdown itself is welcome — headings, bold, tables, code spans, fenced blocks.

## 4. Sources — the order is binding

1. **The code.** Clone and read the repositories involved, including ones in
   other GitHub orgs.
2. **Live APIs** (`gh`, `gcloud`, Linear, Confluence).
3. **The wiki last**, and **date every page you cite**.

When a wiki page contradicts the code, **the code wins**, and the contradiction
goes into the issue. It is information, not a wrinkle to smooth over.

⚠️ **Test access before declaring a repository out of reach.** A `404` from `gh`
means "absent **or** invisible to this token", never "absent". An enterprise EMU
account cannot see repos outside its enterprise — run `gh auth switch` before
concluding. Measured: a whole session was built on a false premise because a
reachable repository had been declared unreachable.

## 5. Evidence

- Every count, every number carries **the command that reproduces it**. A figure
  without its command does not get written.
- Every path cited is verified present: `git cat-file -e origin/main:<path>`.
- Every external URL is tested: `curl -s -o /dev/null -L -w "%{http_code}"`.
- Flags in a cited command are load-bearing. `grep -rl 'backend "gcs"' infra/`
  returns 25; with `--include='*.tf'` it returns 24. Cite the correct form, and
  say why it is the correct one.

## 6. Links — maximum density, inline, no dedicated section

Put links **directly in the text**, on the words they describe. Do **not** add a
"References" or "Links" section at the end unless it genuinely earns its place.

**Every occurrence, in every section.** If a path appears five times, it is
linked five times. The `# Todo` is what people read **while working**, usually
without re-reading the context above it: it must be as densely linked as
`# Contexte`.

> ⚠️ The opposite rule — "link the first mention only" — has been tried. Since a
> path is almost always introduced in the context section, it mechanically
> guarantees link-free Todos. Do not reintroduce it.

| Case | Target |
|---|---|
| Directory | `/tree/main/<path>` — **never** `/blob/` |
| File | `/blob/main/<path>` |
| Glob such as `infra/envs/*` | the real directory, `/tree/main/infra/envs` |
| Identifier with no doc page (a KMS key, a resource, an object name) | **its declaration site in the repo** |
| A sibling issue named in prose ("the previous issue", "the X runbook") | its Linear id |
| A Terraform resource type | the provider registry |

**Link text and target must say the same thing.** Text showing a directory that
points at a file misleads the reader. So does `terraform plan` pointing at the
`init` page.

Never a local filesystem path (`/home/`, `/Users/`, `C:\`, `/tmp/`). Never a
line anchor (`#L21`) — line numbers drift on the first commit; saying "line 21"
in prose is fine and often useful.

### What stays unlinked, deliberately

- A shell command in inline code — a link inside it breaks copy-paste.
- The name of a tool every reader knows; a command's output (`0 to destroy`).
- An object that **nothing declares** in the repo. Verify that before asserting it.
- An identifier whose owning file is already linked in the same sentence.

## 7. Two traps that each cost a full rewrite

1. **Send real accented characters** (é à è ô ç) to the Linear tools. A `\u00e9`
   escape gets double-escaped and renders as literal garbage in the ticket.
2. **Save early and often.** One `patch` call per group of links, never one huge
   call at the end. Measured: across 22 delegations, 3 agents produced pages of
   analysis and never called the write tool at all.

## 8. Ask before starting

Three things that cannot be guessed, and that one sentence settles:

- **Scope** — exactly which issues.
- **Link density** — maximum, or sparse.
- **What is already decided** — otherwise settled decisions get relitigated.
