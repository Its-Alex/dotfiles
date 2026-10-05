import { spawnSync } from "node:child_process"
import type { Plugin } from "@opencode-ai/plugin"

// RTK OpenCode plugin — rewrites commands to use rtk for token savings.
// Requires: rtk >= 0.23.0 in PATH.
//
// This is a thin delegating plugin: all rewrite logic lives in `rtk rewrite`,
// which is the single source of truth (src/discover/registry.rs).
// To add or change rewrite rules, edit the Rust registry — not this file.
//
// Dual entrypoint: the V1 loader calls the default export's `server()`, the
// V2 loader reads `id` + `setup()` and ignores `server()`. Hand-maintained
// until rtk ships V2 support upstream:
// https://github.com/rtk-ai/rtk/issues/3463
// Managed by chezmoi — `rtk init -g --opencode` overwrites this file; run
// `chezmoi apply` to restore it.

const RTK_TIMEOUT_MS = 2000

/** Delegate one command to `rtk rewrite`. Returns undefined when no rule applies. */
function rewriteCommand(command: string): string | undefined {
  try {
    const result = spawnSync("rtk", ["rewrite", command], {
      encoding: "utf8",
      timeout: RTK_TIMEOUT_MS,
      maxBuffer: 1024 * 1024,
    })
    // rtk rewrite exits 3 when a rule applied (stdout holds the rewritten
    // command) and 1 when none matched. Both non-fatal; only trust stdout.
    const rewritten = (result.stdout ?? "").trim()
    return rewritten && rewritten !== command ? rewritten : undefined
  } catch {
    return undefined // rtk missing or unusable — pass through unchanged
  }
}

// V2 entrypoint. Reassign event.input: under V2, mutating the nested object
// in place does not take effect.
async function setup(ctx: any) {
  await ctx.tool.hook("execute.before", async (event: any) => {
    const tool = String(event?.tool ?? "").toLowerCase()
    if (tool !== "bash" && tool !== "shell") return
    const input = event?.input
    if (!input || typeof input !== "object") return
    const command = (input as Record<string, unknown>).command
    if (typeof command !== "string" || !command) return
    const rewritten = rewriteCommand(command)
    if (rewritten) event.input = { ...input, command: rewritten }
  })
}

// V1 entrypoint.
export const RtkOpenCodePlugin: Plugin = async ({ $ }) => {
  try {
    await $`which rtk`.quiet()
  } catch {
    console.warn("[rtk] rtk binary not found in PATH — plugin disabled")
    return {}
  }

  return {
    "tool.execute.before": async (input, output) => {
      const tool = String(input?.tool ?? "").toLowerCase()
      if (tool !== "bash" && tool !== "shell") return
      const args = output?.args
      if (!args || typeof args !== "object") return

      const command = (args as Record<string, unknown>).command
      if (typeof command !== "string" || !command) return

      const rewritten = rewriteCommand(command)
      if (rewritten) {
        ;(args as Record<string, unknown>).command = rewritten
      }
    },
  }
}

export default { id: "rtk", setup, server: RtkOpenCodePlugin }
