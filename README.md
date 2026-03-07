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

Install as a symlink instead of a copy:

```bash
./devenv install --mode symlink --force
```

Remove an installed copy:

```bash
./devenv uninstall
```

## Quick Start

From inside a repo with a supported `.devcontainer`:

```bash
devenv
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
devenv open [project_name] [--workspace PATH] [--rm]
devenv up [--workspace PATH] [--project-name NAME]
devenv down [--workspace PATH] [--project-name NAME]
devenv shell [--workspace PATH] [--project-name NAME] [--service NAME]
devenv exec [--workspace PATH] [--project-name NAME] [--service NAME] -- <command> [args...]
devenv tool <helix|tmux|files> [--workspace PATH] [--project-name NAME] [--service NAME] [-- args...]
devenv host-tool <list|check|install> [tool...] [--print]
devenv container-tool <list|check|install> [tool...] [--print]
devenv host-tmux [--workspace PATH] [--project-name NAME] [--service NAME]
devenv logs [--workspace PATH] [--project-name NAME] [--service NAME]
devenv ps [--workspace PATH] [--project-name NAME]
devenv config [--workspace PATH]
devenv check [--workspace PATH]
devenv install [--prefix PATH] [--mode copy|symlink] [--force]
devenv uninstall [--prefix PATH]
```

## Behavior

- `devenv` behaves like `open`: it starts the environment, opens a shell, and leaves services running when the shell exits.
- `devenv open my-name` overrides the derived runtime name for that session.
- `devenv --rm` tears the stack down after `open`, `shell`, `exec`, or `tool` exits.
- `devenv shell` attaches to the configured service without tearing the stack down by default.
- `devenv exec -- <cmd>` starts the environment if needed, waits until the target container is ready, and then runs the command inside it.
- `forwardPorts` is published on the host as `127.0.0.1:<port>` for the primary service/container.
- `devenv host-tmux` creates or attaches to a host tmux session named after the repo and starts a `devenv shell` in its first window.
- `devenv tool ...` is optional and only works when the repo image already provides that tool.

## Recommended Workflow

The cleanest setup is:

- host machine: `docker`, `docker compose`, `jq`, `tmux` or another multiplexer, and your editor such as Helix or Lapce
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

Use `host-tool` for things that belong on the machine running `devenv`, such as `jq`, `tmux`, `helix`, `lapce`, and `copilot`.

List supported host tools:

```bash
devenv host-tool list
```

Check what is installed:

```bash
devenv host-tool check jq tmux helix copilot
```

Install host tools:

```bash
devenv host-tool install jq tmux helix copilot
devenv host-tool install lapce
```

`copilot` uses the standalone installer:

```bash
curl -fsSL https://gh.io/copilot-install | bash
```

### Container Tools

Use `container-tool` for mutable extras installed inside the active service container.

List supported container tools:

```bash
devenv container-tool list
```

Preview install commands without running them:

```bash
devenv container-tool install --print jq tmux helix git copilot
```

Install tools in the current container:

```bash
devenv container-tool install jq tmux helix git copilot
```

Container-side installs are convenient, but they are not the source of truth. If the tooling matters for the repo, move it into the repo image later.

## Git And SSH In Containers

For Git support inside the container, there are two separate needs:

- install `git` in the image or with `devenv container-tool install git`
- expose credentials to the container

If `SSH_AUTH_SOCK` exists on the host, `devenv` now forwards it automatically for both compose-backed and Dockerfile-based repos. It binds the host socket into the container at `/tmp/devenv-ssh-agent.sock` and exposes `SSH_AUTH_SOCK` for `devenv`-managed shell, exec, and lifecycle commands.

If you do not want that behavior for a session, run `devenv` with `DEVENV_NO_SSH_AGENT_FORWARDING=1`.

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
- `forwardPorts` currently supports numeric ports and `<service>:<port>` entries for the primary service. They are published on `127.0.0.1` rather than all interfaces.
- Editor-specific `customizations` are ignored on purpose.

The next natural expansions are broader Dev Container spec support, better state handling, and richer helper workflows.