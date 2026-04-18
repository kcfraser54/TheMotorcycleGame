# TheMotorcycleGame

A Godot 4 game project. The repository root is a standard Godot project
(`project.godot` lives at the root); a committed iOS Xcode shell lives under
`ios/` and is built by CI.

## CI/CD architecture (Option B: PCK + Xcode)

To avoid Godot's iOS exporter running in CI (which is fragile around bundle
identifiers, signing fields, and export-template validation), the pipeline
splits responsibilities:

- **Godot** exports game *content only* as a `.pck` file (no iOS preset
  validation).
- **Xcode** compiles and signs the iOS app from a committed Xcode project
  shell under `ios/`.
- **GitHub Actions** orchestrates: a Linux job runs `godot --export-pack`,
  a macOS job drops the resulting PCK into `ios/TheMotorcycleGame/` and
  runs `xcodebuild`.

The Xcode shell under `ios/` is **generated once by Godot and committed**.
You only need to regenerate it when the Godot version or any iOS export
option changes (bundle id, icons, capabilities, orientation, version,
launch storyboard, plugins, etc.).

### Workflows

| Workflow                                 | Trigger              | Purpose                                                                |
|------------------------------------------|----------------------|------------------------------------------------------------------------|
| `.github/workflows/pr-ci.yml`            | PRs to `main`        | GUT tests + export `game.pck` + unsigned `xcodebuild` of `ios/` shell  |
| `.github/workflows/bootstrap-ios-shell.yml` | `workflow_dispatch` | Generates the iOS Xcode shell from Godot's iOS exporter, as an artifact |
| `.github/workflows/deploy-testflight.yml`| Push to `main`       | Export `game.pck` + signed `xcodebuild archive` of `ios/` shell + TestFlight upload |

## Bootstrapping / regenerating the iOS Xcode shell

When you first set up the repo, or when you change Godot or any iOS export
setting, regenerate the shell:

1. Open the **Actions** tab on GitHub and run **"Bootstrap iOS Xcode shell"**
   (`workflow_dispatch`).
2. When it finishes, download the `ios-shell` artifact.
3. Replace the contents of `ios/` in the repo with the artifact contents
   (`rm -rf ios && unzip ios-shell.zip -d ios`), and commit on a branch /
   open a PR.
4. From then on, `pr-ci.yml` will build the new shell against every PR's
   freshly-exported PCK.

The bootstrap workflow strips any `*.pck` files from the artifact — the PCK
is regenerated on every CI run via `--export-pack` and must never be
committed (see `.gitignore`).

## Required secrets

PR CI runs fully unsigned and reads no secrets. The TestFlight deploy
workflow needs:

- `APPLE_CERTIFICATE_BASE64`, `APPLE_CERTIFICATE_PASSWORD`,
  `APPLE_PROVISIONING_PROFILE`, `APPLE_TEAM_ID`,
  `APP_STORE_CONNECT_API_KEY_ID`, `APP_STORE_CONNECT_API_ISSUER_ID`,
  `APP_STORE_CONNECT_API_KEY_BASE64`.

`APPLE_TEAM_ID` is now consumed by `xcodebuild` (`DEVELOPMENT_TEAM=...`)
and the `ExportOptions.plist` only — it is **no longer** injected into
`export_presets.cfg`.

## Notes

- `export_presets.cfg` **must** be committed (Godot gitignores it by
  default). The PCK export reads the `iOS` preset to know which resources
  to include.
- Local iOS development is unchanged: open `ios/TheMotorcycleGame.xcodeproj`
  in Xcode after running `godot --headless --export-pack iOS ios/TheMotorcycleGame/TheMotorcycleGame.pck`.
