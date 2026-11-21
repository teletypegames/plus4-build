# plus4-build

CI/CD templates for Commodore Plus/4 (ACME + VICE) game projects, in the same
spirit as [c64-tools](../c64-tools): the Plus/4 shares the C64's 6502 core, so
the toolchain is the same ACME assembler — only the emulator (`xplus4`), the
load address (`$1001`) and the TED registers differ.

- `example-makefile.make` — project Makefile: local dev targets
  (`deps`, `build`, `run`, `clear`, `rebuild`, `rebuildrun`).
- `example-woodpecker.yaml` — a one-line marker (`platform: plus4`): the
  full pipeline (version → build → package → artifact → publish) is served by the update server's Woodpecker
  configuration extension — preview it with
  `curl "https://teletypegames.org/build/config?platform=plus4"`.
- `example-metadata.json` — catalog metadata; the `version` field drives
  the pipeline's version step, the rest (`name`, `title`, `author`, `desc`, `site`,
  `repo`, `license`) is what `WarpEngine::Platforms::Plus4::Service` writes into
  the DB (`site` becomes the "Source Code", `repo` the "Repository"
  external link).
- `example-tasks.json` — VS Code `.vscode/tasks.json`: the make targets as
  `warpengine` tasks (`build`, `clear`, `rebuild`, and `run (VICE)` in a local
  `xplus4`).
- `hello/main.asm` — a Hello World: clears the screen and prints `HELLO WORLD`.
- `warp-template.json` — what *WarpEngine: New Game* in the WarpEngine Toolbox
  copies from this repo: the Makefile, the VS Code tasks and `hello/main.asm` as
  `main.asm`, so a new project builds (`make build`, or the served pipeline's
  `acme -f cbm -o <name>.prg main.asm`) and runs (`make run`, xplus4) right away.
  The toolbox writes the marker, `metadata.json` and `README.md` itself.

## Dev container

`warp-template.json` has a `devcontainer` key that the WarpEngine Toolbox reads
(an older toolbox ignores it): a new project gets `.devcontainer/` from
`example-devcontainer.json` and `example-devcontainer.Dockerfile` — the CI
builder image the host names (`{builderImage}`) plus git and a `dev` user —
so a computer with only Docker builds with the same toolchain as the pipeline.
The tasks of `example-devcontainer-tasks.json` are merged into
`.vscode/tasks.json`: `dev image` builds the container image, `play` builds the
game and plays it in the host's web runtime. VICE is not in the container: `run (VICE)` builds there and runs the build in a local `xplus4`.
For an existing game repo, *WarpEngine: Add Dev Container* adds it and merges
the tasks, keeping yours.

## Usage in a game repo

1. Copy `example-makefile.make` to `Makefile`, set `PROJECT` (and
   `TARGET` if the .prg name differs from `$(PROJECT).prg`).
2. Copy `example-metadata.json` to `metadata.json` and fill it in;
   `name` must match `PROJECT`.
3. Copy `example-woodpecker.yaml` to `.woodpecker.yaml` (a one-line marker — the
   pipeline itself is served by the update server; add `name:` when the
   software name differs from the repo name) and add the
   `application_token` secret in Woodpecker (an ApplicationToken with
   the `update` + `upload` scopes, created in the admin).
4. Copy `example-tasks.json` to `.vscode/tasks.json`.

## Plus/4 specifics

- A BASIC program starts at `$1001` (the C64's is `$0801`), so the SYS stub
  and the `* =` origin differ; the entry point after a minimal stub is
  `$100D` (`SYS 4109`).
- Screen RAM is at `$0C00`, colour RAM at `$0800`; a colour byte is
  `luminance << 4 | hue` (bit 7 flashes).
- Video is the TED at `$FF00`–`$FF3F` (`$FF15` background, `$FF19` border,
  `$FF1D`/`$FF1C` raster line); there is no VIC-II, no SID and no CIA.
- The KERNAL jump table is compatible (`$FFD2` CHROUT, `$FFE4` GETIN).

## Builder image

`builder.Dockerfile` bakes the pipeline's build-step dependencies
(ACME assembler + make) into `git.teletypegames.org/build/plus4-builder`,
so the build step does not run `apt-get` on every run (VICE is a
local-dev tool only and is not included):

```sh
docker build --platform linux/amd64 -f builder.Dockerfile \
  -t git.teletypegames.org/build/plus4-builder:latest .
docker push git.teletypegames.org/build/plus4-builder:latest
```

## Player image

The pipeline's `package` step runs in `git.teletypegames.org/build/commodore-player`,
which lives in [c64-tools](../c64-tools) (`player.Dockerfile`) and serves both
platforms: `commodore-pack plus4 <name> <version>` wraps the `.prg` into an
EmulatorJS browser player (`vice_xplus4` core) and into yapeSDL bundles for
linux-x64, win-x64 and mac-arm64 (Apple Silicon), whose launchers set yapeSDL to Plus/4
mode (`EmulationLevel = 0`) before autostarting the program.

The served pipeline builds the `.prg`, runs `commodore-pack`, uploads
`$(PROJECT)-$(VERSION).prg`, `.metadata.json`, `.html.zip`, `-linux-x64.zip`,
`-win-x64.zip` and `-mac-arm64.zip` via `/build/upload`, then triggers
`/build/publish?platform=plus4&name=$(PROJECT)&version=$(VERSION)`, which
creates/updates the Software row and a Release with the `cartridge`, `html`,
`win_x64`, `linux_x64` and `mac_arm64` assets.
