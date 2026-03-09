# devenv

`devenv` is a small host-side wrapper for repo-owned `.devcontainer` environments.

The goal is straightforward:

- keep SDKs and project tooling out of the host machine
- keep each repo as the source of truth for its own environment
- make container-backed shell workflows easy without depending on a specific editor

## What It Does

`devenv` discovers the current repo's devcontainer config, starts the repo environment, runs supported lifecycle hooks, and gives you a clean way to open shells or execute commands inside the configured container.

It currently supports:

- discovery of `.devcontainer/devcontainer.json` or `.devcontainer.json`
- compose-backed devcontainers with `dockerComposeFile` and `service`
- Dockerfile-based devcontainers with `dockerFile` or `build.dockerfile`
- stable per-repo compose project naming so multiple repos can run at once
- stable per-repo container and image naming for Dockerfile-based repos
- `initializeCommand` on the host
- `onCreateCommand`, `updateContentCommand`, `postCreateCommand`, `postStartCommand`, and `postAttachCommand` when they are strings, arrays, or objects
- `forwardPorts` publishing to `127.0.0.1` for the primary service/container
- shell workflows that either keep the environment running or remove it on exit with `--rm`
- host tmux helpers for terminal-centric workflows
- optional helper commands for host-side and container-side tooling
- runtime state tracking so recreated containers rerun the right lifecycle stages

It does not yet support:

- image-only devcontainer definitions
- Dev Container Features
- editor-specific `customizations`
- full Dev Container spec parity

## Host Requirements

- `docker`
- `docker compose` for compose-backed repos
- `jq`
- `bash`

No Node.js dependency is required.

## Install

Install `devenv` into `~/.local/bin`:

```bash
./devenv install
```

This creates a symlink back to your git checkout, so updates in the repo are picked up immediately.

Remove the installed symlink:

```bash
./devenv uninstall
```

## Quick Start

From inside a repo with a supported `.devcontainer`:

```bash
devenv
```

Start a host-side dev session with a VS Code-like Zellij layout:

```bash
devenv dev
```

Run a command in the container:

```bash
devenv exec -- npm run dev
```

Run a one-off command and remove the environment afterward:

```bash
devenv exec --rm -- npm run dev
```

Inspect what `devenv` discovered:

```bash
devenv config
```

## Commands

```text
devenv
devenv dev [--workspace PATH] [--project-name NAME] [--service NAME] [--rm] [--no-cache]
devenv vibe [--workspace PATH] [--project-name NAME] [--service NAME] [--rm] [--no-cache]
devenv ide [--workspace PATH] [--project-name NAME] [--service NAME] [--rm] [--no-cache]
devenv open [project_name] [--workspace PATH] [--rm] [--no-cache]
devenv up [--workspace PATH] [--project-name NAME] [--no-cache]
devenv down [--workspace PATH] [--project-name NAME]
devenv shell [--workspace PATH] [--project-name NAME] [--service NAME] [--no-cache]
devenv exec [--workspace PATH] [--project-name NAME] [--service NAME] [--no-cache] -- <command> [args...]
devenv tool <helix|micro|fresh|tmux|files|tree|git|ai> [--workspace PATH] [--project-name NAME] [--service NAME] [--no-cache] [-- args...]
devenv host-tool <list|check|install> [tool...] [--print]
devenv container-tool <list|check|install> [tool...] [--print]
devenv host-tmux [--workspace PATH] [--project-name NAME] [--service NAME]
devenv logs [--workspace PATH] [--project-name NAME] [--service NAME]
devenv ps [--workspace PATH] [--project-name NAME]
devenv config [--workspace PATH]
devenv check [--workspace PATH]
devenv install [--prefix PATH] [--force]
devenv uninstall [--prefix PATH]
```

## Behavior

- `devenv` behaves like `open`: it starts the environment, opens a shell, and leaves services running when the shell exits.
- `devenv dev` starts the environment and opens a host-side Zellij layout with a file browser, editor pane, git pane, and a `devenv shell` pane.
- `devenv vibe` starts the environment and opens a host-side Zellij layout with container-only git, AI, and shell panes.
- `devenv ide` is an alias for `devenv dev`.
- `devenv open my-name` overrides the derived runtime name for that session.
- `--no-cache` forces a fresh image rebuild when `devenv` starts the environment.
- `devenv --rm` tears the stack down after `open`, `shell`, `exec`, or `tool` exits.
- `devenv dev --rm` tears the stack down after the Zellij session exits.
- `devenv vibe --rm` tears the stack down after the Zellij session exits.
- `devenv shell` attaches to the configured service without tearing the stack down by default.
- `devenv exec -- <cmd>` starts the environment if needed, waits until the target container is ready, and then runs the command inside it.
- `forwardPorts` is published on the host as `127.0.0.1:<port>` for the primary service/container.
- `devenv host-tmux` creates or attaches to a host tmux session named after the repo and starts a `devenv shell` in its first window.
- `devenv tool ...` is optional and only works when the repo image already provides that tool.

## Recommended Workflow

The cleanest setup is:

- host machine: `docker`, `docker compose`, `jq`, `zellij` or `tmux`, and your editor such as Helix or Micro
- repo containers: language runtimes, package managers, test tools, app dependencies, and repo-specific CLIs

That keeps personal UI tools on the host while keeping SDKs and build tooling inside containers.

### Single Repo

Open your editor on the host:

```bash
hx .
```

Run a shell or command in the container:

```bash
devenv shell
devenv exec -- npm test
```

### Zellij Dev Session

Open a Zellij workspace from the current repo:

```bash
devenv dev
```

The generated dev layout now keeps the working panes inside the container:

- main pane: container-scoped `devenv tool micro`
- right pane: container-scoped AI CLI via `devenv tool ai`, preferring `copilot`, then `gemini`, then `gemini-cli`
- hidden floating shell pane: container shell via `devenv shell`, positioned near the bottom and toggled with `Alt-f`

Recommended host tools:

```bash
devenv host-tool install zellij
devenv host-tool check zellij
```

Recommended container tools for the dev layout:

```bash
devenv container-tool install micro copilot
```

`copilot` can be installed by `devenv`. Gemini is detected if your image already provides it.

If you want to tear the environment down when you leave the Zellij session:

```bash
devenv dev --rm
```

### Zellij Vibe Session

Open a simpler container-only Zellij workspace from the current repo:

```bash
devenv vibe
```

The generated vibe layout keeps all working panes inside the container:

- left pane: container-scoped git UI via `devenv tool git`, preferring `lazygit`, then `gitui`, then `git status`
- right pane: container-scoped AI CLI via `devenv tool ai`, preferring `copilot`, then `gemini`, then `gemini-cli`
- hidden floating shell pane: container shell via `devenv shell`, positioned near the bottom and toggled with Zellij's floating-pane shortcut

By default, the shell starts hidden in `vibe`. Toggle it with `Alt-f`, which maps to Zellij's `ToggleFloatingPanes` action in the default keymap.

Recommended container tools for the vibe layout:

```bash
devenv container-tool install lazygit copilot
```

`copilot` can be installed by `devenv`. Gemini is detected if your image already provides it.

If you want to tear the environment down when you leave the Zellij session:

```bash
devenv vibe --rm
```

### tmux Workflow

Create or attach to a host tmux session for the current repo:

```bash
devenv host-tmux
```

Or build a simple multi-pane layout for the current repo:

```bash
tmux new-session -d -s work -n shell -c "$PWD" 'devenv shell'
tmux split-window -h -t work:shell -c "$PWD" 'devenv shell'
tmux split-window -v -t work:shell.0 -c "$PWD" 'devenv shell'
tmux select-layout -t work:shell tiled
tmux attach -t work
```

Those panes stay visible because each one is an interactive shell. Run long-lived commands in whichever pane you want.

## Tooling Helpers

`devenv` now distinguishes between host-side tooling and container-side tooling.

### Host Tools

Use `host-tool` for things that belong on the machine running `devenv`, such as `jq`, `git`, `helix`, `micro`, `fresh`, `lazygit`, `lf`, `yazi`, and `zellij`.

List supported host tools:

```bash
devenv host-tool list
```

Check what is installed:

```bash
devenv host-tool check jq git helix micro fresh lf yazi lazygit zellij
```

Install host tools:

```bash
devenv host-tool install jq git helix micro fresh
devenv host-tool install lf zellij
devenv host-tool install yazi lazygit
```

`devenv dev` no longer depends on `lf` or `yazi` on the host. They remain available as optional host utilities if you want them separately. `micro` installs with the official `getmic.ro` bootstrap script into `~/.local/bin`. `fresh` installs from the upstream Linux release tarball into `~/.local/share/fresh-editor` with a `~/.local/bin/fresh` symlink. `yazi` installs from the official release musl-linked `.deb` on apt-based systems and via Fedora COPR on `dnf`-based systems. `lazygit` currently uses a Fedora COPR install via `dnf`, and `zellij` installs from the matching `x86_64` or `aarch64` Linux release tarball.

Current host install flows:

```bash
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
curl -fsSL "https://github.com/sxyazi/yazi/releases/download/v26.1.22/yazi-x86_64-unknown-linux-musl.deb" -o "$tmpdir/yazi.deb"
sudo apt-get update
sudo apt-get install --reinstall -y "$tmpdir/yazi.deb"

sudo dnf copr enable lihaohong/yazi -y
sudo dnf install -y yazi

sudo dnf copr enable dejan/lazygit -y
sudo dnf install -y lazygit
```

### Container Tools

Use `container-tool` for mutable extras installed inside the active service container.

List supported container tools:

```bash
devenv container-tool list
```

Preview install commands without running them:

```bash
devenv container-tool install --print jq helix micro fresh git yazi copilot
```

Install tools in the current container:

```bash
devenv container-tool install jq helix micro fresh git yazi copilot
```

Container-side installs are convenient, but they are not the source of truth. If the tooling matters for the repo, move it into the repo image later.

For package-manager based installs, `devenv` runs the install step as `root` with `docker exec -u root`, so the container does not need `sudo` for these mutable installs.

On apt-based containers, `yazi` is installed from the official musl-linked release `.deb` because Debian/Ubuntu repositories may not provide a current `yazi` package and newer glibc-linked builds can be incompatible with older base images.

## Git And SSH In Containers

For Git support inside the container, there are two separate needs:

- install `git` in the image or with `devenv container-tool install git`
- expose credentials to the container

If `SSH_AUTH_SOCK` exists on the host, `devenv` now forwards it automatically for both compose-backed and Dockerfile-based repos. It binds the host socket into the container at `/tmp/devenv-ssh-agent.sock` and exposes `SSH_AUTH_SOCK` for `devenv`-managed shell, exec, and lifecycle commands.

If you do not want that behavior for a session, run `devenv` with `DEVENV_NO_SSH_AGENT_FORWARDING=1`.

If `~/.copilot` or `~/.gemini` exist on the host, `devenv` also mounts them automatically into the container user's home directory as `~/.copilot` and `~/.gemini`, unless the repo already defines its own mount for those paths.

If you do not want that behavior for a session, run `devenv` with `DEVENV_NO_HOST_DOTDIR_FORWARDING=1`.

Mounting all of `~/.ssh` still works, but it is broader than necessary. The safer manual setup is to forward your SSH agent socket explicitly in the repo config.

Example for a Dockerfile-based repo:

```json
{
	"mounts": [
		"source=${localEnv:SSH_AUTH_SOCK},target=/ssh-agent,type=bind"
	],
	"remoteEnv": {
		"SSH_AUTH_SOCK": "/ssh-agent"
	}
}
```

If you really want key files inside the container, prefer a read-only mount instead:

```json
{
	"mounts": [
		"source=${localEnv:HOME}/.ssh,target=/home/node/.ssh,type=bind,readonly"
	]
}
```

Explicit repo config still works. If a repo already defines its own SSH-related `mounts`, `remoteEnv`, or `containerEnv`, `devenv` leaves that in place instead of adding the automatic forwarding.

## Optional In-Container Tools

If a repo image already includes terminal tools, `devenv` can launch them directly:

```bash
devenv tool helix
devenv tool micro
devenv tool fresh
devenv tool files
```

That is optional. The primary workflow is still host editor plus container-backed shells and commands.

## Portability Model

This project treats the target repo's `.devcontainer` as the contract.

That means:

- repo-specific service topology belongs in the target repo
- repo-specific SDKs belong in container images
- repo-specific editor and terminal binaries only need to be in the image if you want to launch them through `devenv tool`
- `devenv` is responsible for discovery, orchestration, lifecycle handling, and attach workflows

If you want reproducible repo tooling, put it in the image. If you want personal convenience tooling, use `host-tool` or a temporary `container-tool` install.

## Notes

- `--rm` does not affect `host-tmux`; it only changes whether the stack is removed after `open`, `shell`, `exec`, or `tool` exits.
- `devenv dev` requires `zellij` on the host. The left pane now uses a built-in picker, so host file managers are no longer required for the dev session.
- `forwardPorts` currently supports numeric ports and `<service>:<port>` entries for the primary service. They are published on `127.0.0.1` rather than all interfaces.
- Editor-specific `customizations` are ignored on purpose.

The next natural expansions are broader Dev Container spec support, better state handling, and richer helper workflows.