// Limits the OpenRouter model picker to an allowlist. Replaces the V1
// `provider.openrouter.whitelist` config field, which OpenCode 2 ignores
// (https://opencode.ai/v2/docs/migrate-v1/#accepted-but-unsupported-fields);
// V2 policies only filter whole providers, not models, so this is done with a
// model transform (https://opencode.ai/v2/docs/build/plugins#models).
//
// OpenCode V2-only: the V1 loader finds no `server()` entry and skips it.
// Plain object export on purpose — `Plugin.define` would require
// `@opencode/plugin` to be resolvable at runtime, which this directory does
// not guarantee.

const ALLOWED_OPENROUTER_MODELS = new Set([
  "anthropic/claude-3-haiku",
  "anthropic/claude-3.5-haiku",
  "anthropic/claude-haiku-4.5",
  "anthropic/claude-opus-4",
  "anthropic/claude-opus-4.1",
  "anthropic/claude-opus-4.5",
  "anthropic/claude-opus-4.6",
  "anthropic/claude-opus-4.7",
  "anthropic/claude-opus-4.8",
  "anthropic/claude-opus-5",
  "anthropic/claude-opus-5.5",
  "anthropic/claude-sonnet-4",
  "anthropic/claude-sonnet-4.5",
  "anthropic/claude-sonnet-4.6",
  "anthropic/claude-sonnet-5",
  "anthropic/claude-sonnet-5.5",
  "anthropic/claude-fable-5",
  "deepseek/deepseek-v3.1-terminus",
  "deepseek/deepseek-v3.2",
  "google/gemini-2.5-flash",
  "google/gemini-2.5-flash-image",
  "google/gemini-2.5-flash-lite",
  "google/gemini-2.5-flash-lite-preview-09-2025",
  "google/gemini-2.5-pro",
  "google/gemini-2.5-pro-preview",
  "google/gemini-2.5-pro-preview-05-06",
  "google/gemini-3-flash-preview",
  "google/gemini-3-pro-image-preview",
  "google/gemini-3.1-flash-image-preview",
  "google/gemini-3.1-flash-lite",
  "google/gemini-3.1-flash-lite-preview",
  "google/gemini-3.1-pro-preview",
  "google/gemini-3.1-pro-preview-customtools",
  "google/gemini-3.5-flash",
  "google/gemma-4-26b-a4b-it",
  "google/gemma-4-26b-a4b-it:free",
  "google/gemma-4-31b-it:free",
  "google/lyria-3-clip-preview",
  "google/lyria-3-pro-preview",
  "minimax/minimax-m2",
  "moonshotai/kimi-k2-thinking",
  "amazon/nova-2-lite-v1",
  "amazon/nova-lite-v1",
  "amazon/nova-micro-v1",
  "amazon/nova-premier-v1",
  "amazon/nova-pro-v1",
  "openai/gpt-oss-120b",
  "openai/gpt-oss-20b",
  "qwen/qwen3-235b-a22b-2507",
  "qwen/qwen3-coder",
  "qwen/qwen3-coder-30b-a3b-instruct",
  "qwen/qwen3-next-80b-a3b-instruct",
  "qwen/qwen3-next-80b-a3b-thinking",
  "writer/palmyra-x5",
  "z-ai/glm-4.7",
  "z-ai/glm-5",
])

async function setup(ctx: any) {
  await ctx.model.transform((editor: any) => {
    editor.list("openrouter").forEach((model: any) => {
      if (!ALLOWED_OPENROUTER_MODELS.has(model.id)) {
        editor.remove(model.providerID, model.id)
      }
    })
  })
}

export default { id: "openrouter-whitelist", setup }
