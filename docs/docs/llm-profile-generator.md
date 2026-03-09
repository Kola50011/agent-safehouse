# Generate a Custom `sandbox-exec` Profile with an LLM

If you want an LLM to build a machine-specific profile for your own setup, copy the prompt below into Claude, Codex, Gemini, or another model. It tells the model to inspect Agent Safehouse's real profile sources first, then ask for only the minimum information needed to generate a least-privilege `.sb` file.

Direct plain-text version: [llm-instructions.txt](/llm-instructions.txt)

## Inspect These References First

Point the LLM at the real source files, not `dist/`:

- [`profiles/00-base.sb`](https://github.com/eugene1g/agent-safehouse/blob/main/profiles/00-base.sb)
- [`profiles/10-system-runtime.sb`](https://github.com/eugene1g/agent-safehouse/blob/main/profiles/10-system-runtime.sb)
- [`profiles/20-network.sb`](https://github.com/eugene1g/agent-safehouse/blob/main/profiles/20-network.sb)
- [`profiles/30-toolchains/`](https://github.com/eugene1g/agent-safehouse/tree/main/profiles/30-toolchains)
- [`profiles/40-shared/`](https://github.com/eugene1g/agent-safehouse/tree/main/profiles/40-shared)
- [`profiles/50-integrations-core/`](https://github.com/eugene1g/agent-safehouse/tree/main/profiles/50-integrations-core)
- [`profiles/55-integrations-optional/`](https://github.com/eugene1g/agent-safehouse/tree/main/profiles/55-integrations-optional)
- [`profiles/60-agents/`](https://github.com/eugene1g/agent-safehouse/tree/main/profiles/60-agents)
- [`profiles/65-apps/`](https://github.com/eugene1g/agent-safehouse/tree/main/profiles/65-apps)
- [`bin/lib/policy.sh`](https://github.com/eugene1g/agent-safehouse/blob/main/bin/lib/policy.sh)
- [`bin/safehouse.sh`](https://github.com/eugene1g/agent-safehouse/blob/main/bin/safehouse.sh)

Helpful docs:

- [Policy Architecture](/docs/policy-architecture)
- [Customization](/docs/customization)
- [Usage](/docs/usage)
- [Options](/docs/options)

The source of truth lives in `profiles/` and `bin/`. `dist/` is generated output.

## Copy/Paste Prompt

```md
I want you to generate a custom macOS `sandbox-exec` profile for my setup.

Before you generate anything, inspect these references to learn the deny-first structure and real profile patterns used by Agent Safehouse:
- https://github.com/eugene1g/agent-safehouse/blob/main/profiles/00-base.sb
- https://github.com/eugene1g/agent-safehouse/blob/main/profiles/10-system-runtime.sb
- https://github.com/eugene1g/agent-safehouse/blob/main/profiles/20-network.sb
- https://github.com/eugene1g/agent-safehouse/tree/main/profiles/30-toolchains
- https://github.com/eugene1g/agent-safehouse/tree/main/profiles/40-shared
- https://github.com/eugene1g/agent-safehouse/tree/main/profiles/50-integrations-core
- https://github.com/eugene1g/agent-safehouse/tree/main/profiles/55-integrations-optional
- https://github.com/eugene1g/agent-safehouse/tree/main/profiles/60-agents
- https://github.com/eugene1g/agent-safehouse/tree/main/profiles/65-apps
- https://github.com/eugene1g/agent-safehouse/blob/main/bin/lib/policy.sh
- https://github.com/eugene1g/agent-safehouse/blob/main/bin/safehouse.sh

Use those references as style and capability guides. Prefer the narrowest possible rules and explain which repo profiles influenced your decisions.

Then gather only the minimum inputs you need from me:
1. My absolute home directory path. Tell me to run `echo $HOME` if I have not given it yet, and use that exact path so the profile grants only what is needed.
2. Any global files or dotfiles I want my agent to access, such as `~/.gitignore`, `~/.gitignore_global`, `~/.npmrc`, `~/.config`, or other machine-global files. Ask whether each one should be read-only or writable.
3. My typical tech stack and tooling, for example Node.js, `pnpm`, `npm`, `yarn`, Python, uv, Bun, Go, Rust, Docker, Homebrew, Git, VS Code, Claude Desktop, Codex, Cursor, or browser tooling. Pick only the integrations that match my actual stack.
4. Where I want to save the profile. Default to `~/.config/sandbox-exec.profile` unless I choose a different path.
5. Whether I want a small wrapper script that automatically grants access to the current working directory, or git root when relevant, whenever I launch the agent.
6. Which shell I use (`zsh`, `bash`, `fish`, etc.) and which agent commands I want shortcuts for in my shell config.
7. Which directories should be read/write, read-only, or fully denied.

After you have enough information, produce:
- A complete `.sb` profile file.
- A short explanation of each access grant.
- A wrapper script, if helpful, that resolves the current working directory and launches `sandbox-exec` with the generated profile.
- A shell config snippet for my shell (for example `~/.zshrc`) that adds shortcuts for my preferred agents.
- A short install and verification checklist.

Requirements:
- Start from deny-by-default.
- Do not grant my entire home directory unless I explicitly ask for it.
- Prefer `literal` or narrow `subpath` rules instead of broad recursive access.
- Keep global dotfile access minimal and explicit.
- Separate read-only grants from read/write grants.
- If my stack implies toolchain access, mirror the least-privilege patterns from Agent Safehouse rather than inventing broad permissions.
- If you are unsure whether something is required, ask me before adding it.
- Keep the final profile commented and easy to audit.

If a wrapper script is generated, prefer behavior like this:
- Detect the current working directory with `pwd -P`.
- Optionally prefer `git rev-parse --show-toplevel` when inside a git repo.
- Pass that directory into the policy in the narrowest way possible.
- Keep the script portable and easy to edit.

If shell shortcuts are generated, make them convenient but explicit, for example:
- `safe-claude`
- `safe-codex`
- `safe-cursor`

Use the repo references above to justify the structure of the profile, but output a self-contained result I can save directly to disk.
```

## Suggested Outcome

The best result is usually:

- one machine-local profile file at `~/.config/sandbox-exec.profile`
- one small wrapper script that grants the current project directory
- one shell snippet that adds agent-specific shortcuts in `~/.zshrc`, `~/.bashrc`, or the user's active shell config

That keeps the durable policy in one place while still making everyday agent launches convenient.
