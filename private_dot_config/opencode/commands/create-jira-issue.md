---
description: Create a Jira issue in the XCP project via mcp-atlassian
model: amazon-bedrock/anthropic.claude-sonnet-4-6
---

Using mcp-atlassian, I want to create an issue in the XCP project.
You can take inspiration from https://xxiigroup.atlassian.net/browse/XCP-7894 (use jira_get_issue to fetch the content of XCP-7894, then explore one or two linked issues).

$ARGUMENTS

Writing guidelines:
- When I use bullet lists, try to use bullet lists too.
- I like explicit communication.
- Repetition of pronouns doesn't bother me if it helps make the point clearer.
- I'm a developer; English terms are fine, and I actually prefer to keep them.
- I like markdown.
- Don't be surprised if you see WikiLinks; keep them if they're present.
- Keep my epistemic hedging markers.
- When useful, add epistemic hedging markers. Don't add them when it doesn't add value.
- Never use a marketing style; that's not my goal or my style.
- Be direct while using a relaxed professional register.
- Keep the hashtags.
- Try to be clear and concise while keeping only the required context and what I specify.
- Use plenty of links to resources (git repo, online docs) directly in the text, and don't add a dedicated section when it's not useful.

Be careful with mcp-atlassian:
- inward_issue = the blocker (the one that must be done first)
- outward_issue = the blocked (the one that cannot start before)
So to say "B is blocked by A":
inward_issue_key = A  (the blocker)
outward_issue_key = B  (the blocked)
link_type = "Blocks"

Here are the Jira ARIs for the Team field:
Team Backend: ari:cloud:identity::team/55bf41de-ae65-461a-8c5d-1d486d47fe5f-30
Team Web: ari:cloud:identity::team/d40e3617-a14f-4793-a86d-dccd229ac978
Team SW: ari:cloud:identity::team/d40e3617-a14f-4793-a86d-dccd229ac978

Mandatory workflow:
1. Draft the summary and description of the issue following the guidelines above.
2. **Show me the full text (summary + description) BEFORE creating the issue.**
3. If I haven't specified the labels and the team (`customfield_10112`), ask me before creating the issue. For the team ask me between `Team SW` or `Team Backend`
4. Only create the issue after my explicit approval.
