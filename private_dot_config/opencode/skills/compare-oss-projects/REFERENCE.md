# Economic Model Analysis Framework

## Signal Matrix

| Signal | Community | VC-backed | Open Core | AGPL / Dual License |
|--------|-----------|-----------|-----------|---------------------|
| **Repository license** | MIT, Apache 2.0, BSD, GPL | MIT, Apache 2.0 | MIT, Apache 2.0, AGPL | AGPL-3.0, SSPL, BUSL |
| **Legal entity** | None or foundation | Company (Inc., Ltd.) | Company (Inc., Ltd.) | Company or individual |
| **Paid offering** | None | SaaS/Cloud (same product) | Enterprise Edition (proprietary features) | Commercial license (same code) |
| **README mentions** | — | "Get started", "Sign up" | "Enterprise", "Pro", "Pricing" | "Commercial license", "Contact us" |
| **Crunchbase** | None | Funding rounds (Seed → Series A/B/C) | Sometimes (if company-backed) | Sometimes |
| **Governance** | BDFL, maintainers | Company-led | Company-led | Company-led |
| **GitHub Sponsors** | Sometimes | No (except employer-sponsored projects) | Sometimes OSS core only | Rarely |
| **Foundation** | Linux Foundation, CNCF, Apache, Eclipse | No (except after donation) | No | No |

## Detailed Models

### Community

Project maintained by volunteers or a foundation.

No commercial entity behind it. No paid version.

Examples: Express.js, curl, FFmpeg, Lua, Redis (before 2018).

Strong signals:
- No "Pricing" page on the website
- Permissive or standard GPL license
- Governance under a foundation (Apache, CNCF, Linux Foundation)
- Commits from diverse individuals, not a single company

### VC-backed

Project backed by a startup that has raised funding.

The OSS product is often **the company's primary product**.

Examples: Docker, GitLab, Grafana, Vercel (Next.js).

Strong signals:
- Crunchbase: 1+ identified rounds (Seed, Series A/B/C)
- Website: "About" page listing investors
- Permissive license (to maximize adoption)
- SaaS/Cloud product based on the same software

Supplementary indicator: check the Crunchbase page. If the company appears with institutional investors (Sequoia, a16z, Accel, Index, etc.), it is VC-backed.

### Open Core

The software core is OSS, but advanced features are proprietary (paid).

The split is explicit: "Community Edition" vs "Enterprise Edition".

Examples: GitLab CE/EE, Mattermost, Nginx, Sidekiq, Temporal.

Strong signals:
- README: CE vs EE comparison table
- Website: clear pricing grid with "Community" / "Enterprise" / "Ultimate"
- Mixed licensing: the core may be MIT, but plugins/modules are proprietary
- "Source-available" ≠ open source (watch for BUSL, Elastic License)

### AGPL / Dual License

Strategy: highly restrictive AGPL license + commercial license sales for companies that do not want to open-source their modified code.

Alternatively: non-OSS license (SSPL, BUSL, Elastic License 2.0) marketed as "open source".

Examples: MongoDB (SSPL), MinIO (AGPL), SuiteCRM (AGPL), MySQL (dual GPL/commercial), Redis Modules (RSAL).

Strong signals:
- LICENSE mentions AGPL-3.0, SSPL, BUSL, or Elastic License 2.0
- Website: "Commercial License" or "License for OEM/ISV"
- Often used to sell a managed offering (DBaaS)
- Note: SSPL and BUSL are not considered OSS by the OSI / Debian / Fedora

## Special Cases

| Case | Description | Classification |
|------|-------------|----------------|
| **Foundation after VC** | Project donated to a foundation after acquisition or abandonment (e.g. Chef, Docker → CNCF) | Community (ex-VC-backed) |
| **Bounty-driven** | Funded via bounties/grants (e.g. Telegraf) | Community |
| **SaaS + OSS** | OSS project + SaaS version hosted by the same company | Open Core |
| **AGPL + SaaS** | AGPL + proprietary SaaS version (e.g. MinIO) | AGPL / Open Core |
| **Source-available** | BSL-style or Elastic License 2.0 | Neither OSS nor proprietary — label as "source-available" |

## How to Verify Each Source

### LICENSE
```
curl -s https://raw.githubusercontent.com/{owner}/{repo}/main/LICENSE | head -20
```

### Crunchbase
```
https://www.crunchbase.com/organization/{company-name}
```
Look up the company name on the project homepage or "About" page.

### GitHub funding
```
gh api repos/{owner}/{repo} --jq '.funding'
```

### GitHub contributors
```
https://github.com/{owner}/{repo}/graphs/contributors
```
If > 50% of commits come from employees of the same company, the project is company-driven.
