---
description: Fetch a HackerNews thread and summarize the comments
model: amazon-bedrock/eu.anthropic.claude-haiku-4-5-20251001-v1:0
---
Use `fetch_html` to retrieve $ARGUMENTS

**Step 1 — Full retrieval**

- Fetch the first page with `fetch_html` and read the total number of comments displayed at the top of the page — this number is your mandatory target.
- The content is likely truncated (200,000 character limit), so chain successive calls incrementing `start_index` by 200,000 each time:
  - `fetch_html(url, start_index=0, max_length=200000)`
  - `fetch_html(url, start_index=200000, max_length=200000)`
  - `fetch_html(url, start_index=400000, max_length=200000)`
  - … until the response comes back empty.
- **You must have retrieved 100% of the comments before moving on to the next step.** Verify that the number of extracted comments matches the initial counter — if it does not, keep paginating.

**Step 2 — Synthesis**

Summarize the key points, insights, and debates from the comments in a concise, structured, and neutral way. Focus on:

The main arguments or opinions expressed.
Any recurring themes or controversies.
Notable examples, data, or anecdotes mentioned.
The overall sentiment (positive, critical, mixed, etc.).

Avoid verbatim quotes unless essential. Format the summary in bullet points or a short paragraph. Be objective and highlight diverse perspectives if present.
