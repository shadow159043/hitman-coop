# Publishing Artur's HITMAN Co-op fork to a private GitHub repository

The source repository and its upstream Git history are in this folder. It should be backed up to a **new, private** repository owned by the intended GitHub account. Do not force-push to Jordan Rodrigues' original repository.

1. Sign in to GitHub as `shadow159043` and create the empty private repository named `hitman-coop` **without** initializing it with a README or license. The private repository was created on GitHub on 2026-10-30.
2. On the main PC, sign in to GitHub for `git` if prompted, and run `powershell -ExecutionPolicy Bypass -File tools/push-artur-backup.ps1` from the project root.
3. Confirm GitHub shows the branch `main`, the original commit history and `docs/two-pc-test-20261030.md`.
4. Create a **private** GitHub release for experimental R2 and attach `_dist/HitmanCoop-0.12.1-3290-sdk420-EXPERIMENTAL-R2.zip` and `_dist/HitmanCoop-Setup-by-Artur-EXPERIMENTAL-R2.exe` with its `.sha256` file.

The private repository backs up tracked **source code, scripts, docs and history**, not ignored `_deps*`, `_build*`, `_dist` or `_localtest`. Those are stored in a separate local snapshot as described in `docs/artur-edition.md`. Raw test logs and backups can contain personal environment details, so they should not be uploaded unreviewed.

Always retain the original GPL-3.0 license, credits, and upstream URL.
