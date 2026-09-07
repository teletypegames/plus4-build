# plus4-build

CI/CD templates for Commodore Plus/4 (ACME + VICE) game projects, in the same
spirit as [c64-tools](../c64-tools): the Plus/4 shares the C64's 6502 core, so
the toolchain is the same ACME assembler — only the emulator (`xplus4`), the
load address (`$1001`) and the TED registers differ.

- `example-makefile.make` — project Makefile: local dev targets
  (`deps`, `build`, `run`, `clear`, `rebuild`, `rebuildrun`).
- `example-woodpecker.yaml` — a one-line marker (`platform: plus4`): the
  full pipeline (version → build → artifact → publish) is served by the update server's Woodpecker
  configuration extension — preview it with
  `curl "https://teletypegames.org/build/config?platform=plus4"`.
- `example-metadata.json` — catalog metadata; the `version` field drives
  the pipeline's version step, the rest (`name`, `title`, `author`, `desc`, `site`,
  `repo`, `license`) is what `WarpEngine::Platforms::Plus4::Service` writes into
  the DB (`site` becomes the "Source Code", `repo` the "Repository"
  external link).
- `example-tasks.json` — VS Code `.vscode/tasks.json` wrapping the local
  make targets.

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

The served pipeline uploads `$(PROJECT)-$(VERSION).prg` and
`$(PROJECT)-$(VERSION).metadata.json` via `/build/upload`, then triggers
`/build/publish?platform=plus4&name=$(PROJECT)&version=$(VERSION)`, which
creates/updates the Software row and a Release with `cartridge_path`.
