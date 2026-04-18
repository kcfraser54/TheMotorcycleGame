# TheMotorcycleGame

A Godot 4.6 motorcycle game targeting iOS, built with GDScript and the
mobile renderer. The repository root is a standard Godot project
(`project.godot` lives at the root).

## CI/CD Strategy

The pipeline uses GitHub Actions across four workflows. Godot's iOS
exporter generates an Xcode project directly (`--export-release`), and
Xcode then compiles, signs, and archives the app for TestFlight.

### Workflows

| Workflow | File | Trigger | What it does |
|---|---|---|---|
| **PR Tests** | `pr-tests.yml` | Pull requests to `main` | Placeholder for automated tests (e.g. GUT). Currently passes with a no-op step — ready to wire in a test runner when tests are added. |
| **PR Build Verification** | `pr-build.yml` | Pull requests to `main` | Installs Godot + export templates on macOS, runs `godot --export-release` to produce an Xcode project under `ios/`. Verifies the project exports cleanly — no signing or uploading. |
| **Deploy to TestFlight** | `deploy-testflight.yml` | Manual (`workflow_dispatch`) | Full release pipeline. Exports the Xcode project via Godot, installs the Apple distribution certificate and provisioning profile from GitHub Secrets, builds and archives with `xcodebuild`, then uploads the `.ipa` to TestFlight via `xcrun altool`. |
| **Export Diagnostic** | `diag.yml` | Manual (`workflow_dispatch`) | Debugging helper. Installs Godot + export templates, then inspects the template contents and export configuration. Used when troubleshooting export failures. |

### How the build works

1. **Godot export** — `godot --headless --export-release "iOS"` reads
   `export_presets.cfg` (the `iOS` preset) and generates a full Xcode
   project at `ios/TheMotorcycleGame.xcodeproj`.
2. **Code signing** — The deploy workflow installs an Apple distribution
   certificate and provisioning profile (both stored as base64-encoded
   GitHub Secrets) into a temporary macOS keychain.
3. **Xcode build** — `xcodebuild` compiles and archives the project.
   `DEVELOPMENT_TEAM` and `PROVISIONING_PROFILE_SPECIFIER` are injected
   from secrets — they are not stored in committed files.
4. **TestFlight upload** — `xcrun altool` uploads the `.ipa` using an
   App Store Connect API key (also from secrets).

### Required Secrets

PR workflows run unsigned and read **no secrets**. The TestFlight deploy
workflow needs the following configured in **Settings → Secrets → Actions**:

| Secret | Purpose |
|---|---|
| `APPLE_CERTIFICATE_BASE64` | Base64-encoded `.p12` distribution certificate |
| `APPLE_CERTIFICATE_PASSWORD` | Password to decrypt the `.p12` |
| `APPLE_PROVISIONING_PROFILE` | Base64-encoded `.mobileprovision` file |
| `APPLE_PROVISIONING_PROFILE_NAME` | Name of the provisioning profile for Xcode |
| `APPLE_TEAM_ID` | Apple Developer Team ID (passed to `xcodebuild`) |
| `APP_STORE_CONNECT_API_KEY_ID` | App Store Connect API key ID |
| `APP_STORE_CONNECT_API_ISSUER_ID` | App Store Connect issuer ID |
| `APP_STORE_CONNECT_API_KEY_BASE64` | Base64-encoded `.p8` API key file |

### Notes

- `export_presets.cfg` **must** be committed — Godot reads it to determine
  export settings (resources to include, architecture, icons, etc.).
- The `ios/` directory is generated at build time by CI and should not be
  committed. The `.gitignore` excludes build artifacts within it.
- Local iOS development: run
  `godot --headless --export-release "iOS" ios/TheMotorcycleGame.xcodeproj`,
  then open the resulting project in Xcode.
