// OpenRouter model allowlist. Replaces the V1 `provider.openrouter.whitelist`,
// which V2 ignores (opencode.ai/v2/docs/migrate-v1/#accepted-but-unsupported-fields);
// V2 policies filter whole providers, so this uses a model transform
// (opencode.ai/v2/docs/build/plugins#models).
//
// V2-only (the V1 loader finds no `server()` export and skips it), and a plain
// object export because `Plugin.define` needs `@opencode/plugin` at runtime.
//
// Whole vendor prefixes cover Claude and Gemini, including their `:batch`/`:free`
// variants and `~…-latest` aliases, so new releases need no edit here.

const ALLOWED_OPENROUTER_PREFIXES = ["anthropic/", "google/gemini"]

const ALLOWED_OPENROUTER_MODELS = new Set([
  "deepseek/deepseek-v3.1-terminus",
  "deepseek/deepseek-v3.2",
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

function isAllowed(modelID: string): boolean {
  if (ALLOWED_OPENROUTER_MODELS.has(modelID)) return true
  const bare = modelID.replace(/^~/, "")
  return ALLOWED_OPENROUTER_PREFIXES.some((prefix) => bare.startsWith(prefix))
}

async function setup(ctx: any) {
  await ctx.model.transform((editor: any) => {
    editor.list("openrouter").forEach((model: any) => {
      if (!isAllowed(model.id)) {
        editor.remove(model.providerID, model.id)
      }
    })
  })
}

export default { id: "openrouter-whitelist", setup }
