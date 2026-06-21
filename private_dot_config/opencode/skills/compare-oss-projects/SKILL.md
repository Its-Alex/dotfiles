---
name: compare-oss-projects
description: >
  Compare multiple open source projects in the same ecosystem across 4 axes:
  age, tech stack, popularity (GitHub stars), and economic model
  (community / VC-backed / open core / AGPL). Start with a multi-source
  discovery phase (GitHub search, awesome lists, HN Algolia, web) to
  identify relevant projects, collect metrics via a shell script using the
  GitHub API, analyze each project's economic model by inspecting the
  license, README, website, and Crunchbase, then produce a comparative
  Markdown table.
  Trigger on: "compare", "choose between", "which open source project",
  "ecosystem", or any request to evaluate open source alternatives.
---

# compare-oss-projects

## Workflow

### Phase 0 — Discovery

Identify projects in a given ecosystem:

1. **GitHub search**
   - `gh search repos "<topic>" --stars:>1000 --limit 20`
   - Search by topic: `gh search repos "topic:<topic>"`
   - Sort by stars to identify leaders
2. **Awesome lists**
   - Search for "awesome-<topic>" repos on GitHub
   - Read their README and extract the project list
3. **HN Algolia** (via web `fetch`)
   - Search `alternatives to <topic>`, `best <topic>`, `<topic> vs`
   - Use the format: `https://hn.algolia.com/?q=alternatives+to+<topic>`
4. **Web fetch**
   - Comparison sites, AlternativeTo, libhunt
   - "comparison", "<topic> open source projects"

**Deliverable**: a shortlist of 3 to 8 projects proposed to the user. Wait for approval before moving to phase 1.

### Phase 1 — Metrics collection

```bash
scripts/gather-metrics.sh owner/repo1 owner/repo2 owner/repo3 ...
```

Produces a JSON object with raw metrics per project:
`repo`, `stars`, `created_at`, `language`, `topics`, `license`, `pushed_at`, `forks`, `description`.

### Phase 2 — Economic model analysis

For each approved project, inspect these sources in order:

1. **LICENSE file** — read its contents to identify the exact license
   - Read the file via the raw GitHub URL: `https://raw.githubusercontent.com/{owner}/{repo}/main/LICENSE`
2. **GitHub funding** — `gh api repos/{owner}/{repo} --jq '.funding'` or check the `Funding` field in the UI
3. **README** — look for mentions of: "Enterprise", "Pro", "Cloud", "Premium", "Pricing", "Get a quote", "Commercial"
4. **Website** (if listed in the repo description) — is there a "Pricing" page?
5. **Crunchbase** — `https://www.crunchbase.com/organization/{company-name}` to look up funding rounds
6. **GitHub contributors graph** — `https://github.com/{owner}/{repo}/graphs/contributors` to see whether commits come from a single company

Use the framework in [REFERENCE.md](REFERENCE.md) to determine the model.

### Phase 3 — Table output

Generate a Markdown table:

| Project | Age | Stars | Stack | License | Economic model | Signals |
|---------|-----|-------|-------|---------|----------------|---------|
| `expressjs/express` | 15 yrs | 65k+ | JavaScript | MIT | Community | ... |

Add 2–3 summary sentences per project explaining the classification.

The table may be followed by a **Verdict** section summarizing the relative strengths and weaknesses of each project.

## Collection script

See [scripts/gather-metrics.sh](scripts/gather-metrics.sh).

Dependencies: `jq` + `gh` (recommended) or `curl`.

## Notes

- The unauthenticated GitHub API is limited to 60 requests/hour. Use `gh` (authenticated via `gh auth login`) to raise the limit to 5000 requests/hour.
- `gather-metrics.sh` supports both modes: `gh` when available, fallback to `curl`.
