# The Ultimate .gitignore for AI Development

[![verify](https://github.com/vikichand/the-ultimate-gitignore-ai/actions/workflows/verify.yml/badge.svg)](https://github.com/vikichand/the-ultimate-gitignore-ai/actions/workflows/verify.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![assertions](https://img.shields.io/badge/assertions-333-brightgreen.svg)](tests/)

A `.gitignore` for repos where people and coding agents share a working directory.

Covers Claude Code, Cursor, Copilot, Codex, Gemini CLI, Windsurf, Cline, Roo, Kilo, Aider, Continue, Zed, JetBrains Junie, Kiro, Amazon Q, Amp, opencode, Crush, Goose, SpecStory and Impeccable, plus spec-driven tooling (Spec Kit, BMAD, Task Master), model weights, vector stores, experiment trackers, eval runners and the usual Python/JS build output.

Every non-obvious entry is traced to an official doc or the tool's own source. The whole file is tested with `git check-ignore` on every push.

## Quickstart

```bash
curl -o .gitignore https://raw.githubusercontent.com/vikichand/the-ultimate-gitignore-ai/main/ultimate.gitignore
```

Appending to one you already have:

```bash
curl -s https://raw.githubusercontent.com/vikichand/the-ultimate-gitignore-ai/main/ultimate.gitignore >> .gitignore
```

Then run the one check that matters. This lists files already tracked in git that your new rules would ignore — the silent-breakage case:

```bash
git ls-files -i -c --exclude-standard
```

Empty output means you are clean. Anything listed is still tracked (a `.gitignore` never untracks retroactively); use `git rm --cached <path>` if you actually want it gone.

To ask why one specific file is being ignored:

```bash
git check-ignore -v path/to/file
```

That prints the exact file, line number and pattern responsible. It is the only reliable way to find a silent drop, because `git status` never mentions ignored files.

## Updating

The file is wrapped in `# >>> the-ultimate-gitignore-ai:START` / `# <<< ...:END` markers. Anything you write **outside** them is yours, and `update.sh` never touches it:

```bash
curl -fsSLO https://raw.githubusercontent.com/vikichand/the-ultimate-gitignore-ai/main/update.sh
sh update.sh                 # updates ./.gitignore
sh update.sh path/to/project # or another project's
```

Keep `update.sh` around and re-run it whenever you want the latest; it replaces only the managed block, reports a no-op when you are already current, and refuses to write anything if the download is not this file (a 404 body, a captive-portal page, a truncated transfer). A `.gitignore` with no markers is never rewritten in place — the block is appended below your rules instead.

Downloading and running it in two steps is deliberate. `curl … | sh` runs code you have not seen, and this file exists partly to stop that class of accident; download it, glance at it, then run it.

If you would rather not keep a script, re-fetch the file by hand and paste your own rules back — the markers show you exactly which region is managed.

## Why another one

Most "AI-era .gitignore" lists are assembled from other lists. This one was built by reading the vendors' documentation and, where the docs were wrong or silent, their source. Three things fall out of that:

**It does not blanket-ignore agent directories.** `.claude/`, `.cursor/`, `.windsurf/`, `.kiro/` and `.specify/` are authored team config that the vendors tell you to commit. Ignoring them deletes your team's agent setup from the repo.

**It refuses the greedy patterns.** `*.bin` matches the `node_modules/.bin` directory. `*.key` eats Apple Keynote files. `*.lock` eats `Cargo.lock` and `poetry.lock`. `.terraform*` eats the dependency lock file HashiCorp tells you to commit. Half the test suite exists to prove those files survive.

**It is tested.** 333 assertions run in CI on Ubuntu and macOS. 148 of them assert that a file is *not* ignored.

## The rule

Sort every AI artifact into one of three buckets.

| Bucket | Examples | Verdict |
|---|---|---|
| **Team intent** | rules, skills, agents, commands, hooks, prompts, specs | **Commit.** Human-authored, reviewable in a PR, useful to everyone |
| **Per-dev override** | `settings.local.json`, `CLAUDE.local.md`, `*.user.toml`, `config.local.json` | **Ignore.** Named for it, by convention across every vendor |
| **Machine state** | caches, transcripts, screenshots, session DBs, secrets | **Ignore.** Regenerable, private, or both |

The naming is consistent enough to be a heuristic: if a filename contains `.local.` or `.user.`, it is bucket two.

## Commit or ignore, per tool

The complete "do not commit" list is short. Everything not named here is team intent.

| Tool | Ignore | Commit |
|---|---|---|
| **Claude Code** | `.claude/settings.local.json`, `.claude/agent-memory-local/`, `CLAUDE.local.md`, `.claude/skills/*/tmp/` | `.claude/settings.json`, `.claude/skills/`, `.claude/agents/`, `.claude/commands/`, `.claude/rules/`, `.claude/hooks/`, `CLAUDE.md`, `.mcp.json` |
| **Impeccable** | `.impeccable/config.local.json`, `.impeccable/hook.*.json`, `.impeccable/*.png`, `.impeccable/live/{sessions,previews,cache}/` | `.impeccable/config.json`, `.impeccable/design.json`, `.impeccable/live/config.json`, `PRODUCT.md`, `DESIGN.md` |
| **Cursor** | nothing by default — `.cursor/mcp.json` ships as a commented-out toggle in the file; uncomment it if yours holds literal keys instead of `${env:...}` | `.cursor/rules/`, `.cursorignore`, `.cursorindexingignore`, `.cursor/skills/`, `.cursor/hooks.json` |
| **Copilot** | nothing | `.github/copilot-instructions.md`, `.github/instructions/`, `.github/prompts/`, `.github/agents/` |
| **Codex** | nothing project-local | `AGENTS.md`, `.codex/config.toml`, `.codex/hooks.json` |
| **Gemini CLI** | `.env` | `GEMINI.md`, `.gemini/settings.json`, `.geminiignore`, `.gemini/commands/` |
| **Windsurf** | nothing | `.windsurf/rules/`, `.windsurf/workflows/`, `.windsurf/skills/`, `.codeiumignore` |
| **Cline / Roo / Kilo** | `.roo/mcp.json`, `.kilocode/mcp.json`, `kilo.jsonc` | `.clinerules/`, `.roo/rules/`, `.roomodes`, `.kilo/rules/`, the `*ignore` files |
| **Aider** | `.aider*` (it self-ignores) | `.aiderignore`, `CONVENTIONS.md` |
| **Crush** | `.crush/` — conversation SQLite DB **inside your repo** | `CRUSH.md`, `.crushignore` |
| **Junie / Kiro / Amazon Q** | `.junie/config.json`, `.junie/mcp/mcp.json`, `.kiro/settings/mcp.json`, `.amazonq/mcp.json` | `.junie/AGENTS.md`, `.kiro/specs/`, `.kiro/steering/`, `.amazonq/rules/` |
| **Spec Kit / BMAD / Task Master** | `.specify/extensions/.cache/`, `_bmad/*.user.toml`, `.memlog.md`, `.taskmaster/state.json` | `.specify/`, `specs/`, `_bmad/`, `.taskmaster/config.json`, `.taskmaster/tasks/` |

Two things worth knowing about Claude Code specifically. Its session transcripts, todos, file history and plugin caches all live in `~/.claude/`, not in your repo, so there is nothing else to exclude. And when it creates `settings.local.json` it adds the rule to your **global** `~/.config/git/ignore`, which your teammates never see — which is exactly why the rule needs to be in the repo's `.gitignore` too. Anthropic's docs say so directly.

## What other lists get wrong

Each of these appears in circulating "AI .gitignore" templates and each is wrong.

| Claim | Reality |
|---|---|
| `.copilotignore` | Does not exist. Copilot content exclusion is a server-side org setting, not a repo file |
| `.windsurfignore` | Does not exist. Windsurf's file is `.codeiumignore` |
| `.aiexclude` for Copilot | Wrong vendor. It is Google's, for Gemini Code Assist / Android Studio / Firebase Studio |
| `.aiexclude` for Gemini CLI | Wrong product. The CLI uses `.geminiignore` |
| `*.bin` | Matches the `.bin` **directory**. Negation cannot rescue anything under it |
| `.terraform*` | Catches `.terraform.lock.hcl`, which HashiCorp tells you to commit |
| `models/` | Is source code in Django, Rails, SQLAlchemy and FastAPI, and unanchored it matches at any depth |
| `storage/` | Is a first-class committed directory in Laravel |
| `*.h5` | Is the standard scientific data container, not just a Keras artifact |
| `*.crt` `*.cer` | Are **public** certificates that CI needs |
| Libraries should not commit lockfiles | Misreads npm's rule about *publishing* `npm-shrinkwrap.json`. Yarn: "should always be stored within your repository (even if you develop a library)" |
| `.bmad-core/` | BMAD v6 uses `_bmad/` — underscore, not dot. A `.bmad*` glob misses all of it |
| `next-env.d.ts` should be committed | Next.js reversed this. Current docs: "Add it to `.gitignore`. If your project already tracks the file, remove it from Git" |

One more, and it is the one that bites hardest:

```gitignore
*.jks    # android keystore
```

Git only treats `#` as a comment at the **start of a line**. That pattern is `*.jks    # android keystore`, which matches nothing. The rule is dead and nothing tells you. `verify.sh` scans for this; every comment in `ultimate.gitignore` is on its own line.

## Verify it yourself

```bash
./verify.sh
```

It builds a throwaway repo, materialises every path in `tests/must-be-ignored.txt` and `tests/must-be-tracked.txt`, and asks `git check-ignore` about each one.

```
  must be ignored   185 paths, 0 missed
  must be tracked   148 paths, 0 wrongly ignored
  dead patterns     0
  ------------------------------------------
  PASS — 333 assertions
```

It neutralises your global and system git config first, so a personal `~/.config/git/ignore` cannot make the suite pass for the wrong reason.

To test a different file:

```bash
./verify.sh path/to/other.gitignore
```

`update.sh` has its own suite, since it edits a file you keep your own rules in:

```bash
./tests/test-update.sh
```

13 assertions, run offline against a local stand-in for upstream: the managed block updates, rules above and below it survive, a marker-less file is appended to rather than rewritten, and a payload that is not this file is refused without touching your `.gitignore`.

## Things the file deliberately leaves to you

Some questions have no correct answer, so they are marked in place rather than decided for you.

- **`.impeccable/critique/`** — Impeccable's README says keep the reports tracked; its own repo ignores them except `ignore.md`. Their guidance contradicts itself. Commented out, pick one.
- **`*.tfvars`** — `github/gitignore` ignores it, HashiCorp says only "if it contains sensitive values". Blanket-ignoring breaks the common `environments/prod.tfvars` pattern that holds only region and instance size. Commented out.
- **`/runs/` and `/logs/`** — anchored to the repo root, but delete them if you have a real `logs/` package.
- **`.env` under Vite** — Vite expects `.env` and `.env.[mode]` to be *committed* as non-secret build defaults and only `*.local` ignored. Check before applying the secrets block.
- **`*.jks` `*.keystore` `*.ppk`** — no vendor documentation behind these. Android *debug* keystores are sometimes committed on purpose.

Entries marked `[?]` in the file are convention rather than anything documented.

## Also worth doing

A `.gitignore` does not stop an agent reading a file off disk. Agents scan the filesystem, not the git index. Mirror your secret patterns into the tool-native exclusion files, which differ per vendor:

| Tool | File |
|---|---|
| Cursor | `.cursorignore` blocks access entirely; `.cursorindexingignore` only excludes from search |
| Gemini CLI | `.geminiignore` |
| Gemini Code Assist / Android Studio / Firebase Studio | `.aiexclude` |
| Windsurf | `.codeiumignore` |
| Cline | `.clineignore` |
| Roo | `.rooignore` |
| Kilo | `.kilocodeignore` |
| JetBrains AI | `.aiignore` |
| Copilot | server-side content exclusion only, no repo file |

And if a secret does land in a commit: rotate it first, before anything else. `git rm --cached` and a new ignore rule do not remove it from history, where it stays reachable via reflog, forks, clones and PR refs.

## Contributing

Corrections are welcome, especially ones that catch a false positive.

1. Add the path to `tests/must-be-ignored.txt` or `tests/must-be-tracked.txt`
2. Run `./verify.sh` and watch it fail
3. Fix `ultimate.gitignore`
4. Run it again

Two rules for new entries. Cite the official doc or the source line in your PR — "I have seen this in other templates" is not evidence. And put comments on their own line, never trailing a pattern.

If you are adding a vendor path, please also say whether the vendor documents it as team-shared or machine-local. That distinction is the whole point of the file.

## Sources

Claude Code: [.claude directory](https://code.claude.com/docs/en/claude-directory) · [settings](https://code.claude.com/docs/en/settings) · [skills](https://code.claude.com/docs/en/skills) · [subagents](https://code.claude.com/docs/en/sub-agents) · [MCP](https://code.claude.com/docs/en/mcp) · [plugins reference](https://code.claude.com/docs/en/plugins-reference)

Agents: [Impeccable](https://github.com/pbakaus/impeccable) · [Cursor rules](https://cursor.com/docs/rules) · [Copilot custom instructions](https://docs.github.com/en/copilot/reference/custom-instructions-support) · [Copilot content exclusion](https://docs.github.com/en/copilot/how-tos/configure-content-exclusion/exclude-content-from-copilot) · [Codex config](https://developers.openai.com/codex/config-basic) · [Gemini CLI ignore](https://github.com/google-gemini/gemini-cli/blob/main/docs/cli/gemini-ignore.md) · [aiexclude](https://docs.cloud.google.com/gemini/docs/codeassist/create-aiexclude-file) · [Windsurf ignore](https://docs.windsurf.com/context-awareness/windsurf-ignore) · [Cline config](https://docs.cline.bot/getting-started/config) · [Roo MCP](https://docs.roocode.com/features/mcp/using-mcp-in-roo) · [Aider options](https://aider.chat/docs/config/options.html) · [Kiro specs](https://kiro.dev) · [AGENTS.md](https://agents.md)

Ecosystem: [gitignore(5)](https://git-scm.com/docs/gitignore) · [github/gitignore](https://github.com/github/gitignore) · [Terraform dependency lock](https://developer.hashicorp.com/terraform/language/files/dependency-lock) · [DVC init](https://doc.dvc.org/command-reference/init) · [Playwright auth](https://playwright.dev/docs/auth) · [uv project layout](https://docs.astral.sh/uv/concepts/projects/layout/) · [pnpm and git](https://pnpm.io/git) · [Yarn QA](https://yarnpkg.com/getting-started/qa) · [Next.js TypeScript](https://nextjs.org/docs/app/api-reference/config/typescript) · [Cloudflare local data](https://developers.cloudflare.com/workers/development-testing/local-data/) · [removing sensitive data](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository)

## License

MIT. See [LICENSE](LICENSE).

Built by [Vikash Chand](https://github.com/vikichand). Corrections welcome — open an issue with the doc or source line that proves the current entry wrong.
