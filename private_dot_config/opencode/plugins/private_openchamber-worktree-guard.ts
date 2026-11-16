// Blocks hand-made worktrees while OpenChamber's tools are loaded, so they are
// only ever created by OpenChamber and land in its data-dir folder
// (`<opencode data>/worktree/<projectID>`).
// V2-only (the V1 loader skips an export without `server()`), plain object
// export because `Plugin.define` needs `@opencode/plugin` at runtime.

const CREATE_WORKTREE = /\bgit\b[^\n;&|()]*\bworktree\s+add\b/;

const QUOTED = /"[^"]*"|'[^']*'/g;

const HEREDOC = /<<-?\s*['"]?(\w+)['"]?[\s\S]*?\n[\s\S]*?\n\s*\1\b/g;

// Quoted spans and heredoc bodies are data, not commands: a commit message
// explaining the rule must not trip the rule.
function commandWithoutData(command: string): string {
  return command.replace(HEREDOC, " ").replace(QUOTED, " ");
}

const WORKTREE_DIRECTORY = /"worktree"\s*:\s*\{[^}]*"directory"/;

const BLOCKED = [
  "BLOCKED: git worktree add is not allowed while the OpenChamber tools are loaded.",
  "Create the worktree with tools.openchamber instead: session.moveToWorktree to move this session onto a new branch, or session.create with `worktree` to start a new session in one.",
  "OpenChamber puts it in ~/.local/share/opencode/worktree/<project-id>/<name>; do not move it, do not set worktree.directory.",
].join(" ");

const BLOCKED_DIRECTORY = [
  'BLOCKED: "worktree.directory" moves new worktrees out of ~/.local/share/opencode/worktree/<project-id>/.',
  "Leave it unset; OpenChamber's data-dir default is the folder worktrees must live in.",
].join(" ");

// Enforcement can only be widened, never lifted: the variable lets a bare CLI or
// a script opt in, it does not let the guard be switched off.
const FORCED = process.env.OPENCODE_OPENCHAMBER_WORKTREE_GUARD === "1";

let openChamberLoaded = false;

async function openChamberToolLoaded(ctx: any): Promise<boolean> {
  if (FORCED || openChamberLoaded) return true;
  openChamberLoaded = (await ctx.tool.list()).some((tool: any) => /openchamber/i.test(String(tool?.id ?? "")));
  return openChamberLoaded;
}

async function setup(ctx: any) {
  const registrations: Array<{ dispose(): Promise<void> }> = [];

  try {
    registrations.push(
      await ctx.tool.hook("execute.before", async (event: any) => {
        const command = event?.input?.command ?? event?.args?.command;
        const written = [event?.input?.content, event?.input?.newString, event?.input?.patch]
          .filter((part) => typeof part === "string")
          .join("\n");
        const addsWorktree = typeof command === "string" && CREATE_WORKTREE.test(commandWithoutData(command));
        const movesWorktrees =
          /opencode\.jsonc?$/.test(String(event?.input?.path ?? event?.input?.filePath ?? "")) &&
          WORKTREE_DIRECTORY.test(written);
        if (!addsWorktree && !movesWorktrees) return;

        if (!(await openChamberToolLoaded(ctx))) return;

        throw new Error(addsWorktree ? BLOCKED : BLOCKED_DIRECTORY);
      }),
    );
  } catch (error) {
    console.error(`[openchamber-worktree-guard] tool hook unavailable: ${error}`);
  }

  try {
    registrations.push(
      await ctx.shell.hook("create.before", async (event: any) => {
        if (!CREATE_WORKTREE.test(commandWithoutData(String(event?.command ?? "")))) return;

        if (!(await openChamberToolLoaded(ctx))) return;

        throw new Error(BLOCKED);
      }),
    );
  } catch (error) {
    console.error(`[openchamber-worktree-guard] shell hook unavailable: ${error}`);
  }

  try {
    registrations.push(
      await ctx.permission.hook("evaluate", async (event: any) => {
        const resources: string[] = Array.isArray(event?.resources) ? event.resources : [];
        if (!resources.some((resource) => CREATE_WORKTREE.test(commandWithoutData(resource)))) return;

        if (!(await openChamberToolLoaded(ctx))) return;

        event.effect = "deny";
        event.message = BLOCKED;
      }),
    );
  } catch (error) {
    console.error(`[openchamber-worktree-guard] permission hook unavailable: ${error}`);
  }

  return async () => {
    for (const registration of registrations) await registration.dispose().catch(() => {});
  };
}

export default { id: "openchamber-worktree-guard", setup };
