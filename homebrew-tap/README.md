# homebrew-shotx

Homebrew tap for [ShotX](https://github.com/aimen08/shotx).

```bash
brew tap aimen08/shotx https://github.com/aimen08/homebrew-shotx
brew install --cask shotx
```

After install, **right-click → Open** on first launch (Gatekeeper warning, the app is ad-hoc signed). Future updates are delivered in-app via Sparkle.

---

## Maintaining this tap

This directory is the **source of truth** that lives inside the main `shotx` repo at `homebrew-tap/`. The published tap repo at `github.com/aimen08/homebrew-shotx` is a mirror of this directory's contents.

To publish changes:

```bash
# from the shotx repo root, after a new release is out:
cd homebrew-tap
# bump version + sha256 in Casks/shotx.rb (see below)
# then push to the tap repo
```

### Bumping the cask after a release

```bash
VERSION=1.9.8  # whatever you just released
SHA=$(curl -sL "https://github.com/aimen08/shotx/releases/download/v${VERSION}/ShotX-${VERSION}.dmg" | shasum -a 256 | cut -d' ' -f1)
sed -i '' "s/version \".*\"/version \"${VERSION}\"/" Casks/shotx.rb
sed -i '' "s/sha256 \".*\"/sha256 \"${SHA}\"/" Casks/shotx.rb
```

Then commit and push that change to the `aimen08/homebrew-shotx` repo.

### First-time setup of the tap repo

```bash
gh repo create aimen08/homebrew-shotx --public --description "Homebrew tap for ShotX"
git clone git@github.com:aimen08/homebrew-shotx.git /tmp/homebrew-shotx
cp -r homebrew-tap/* /tmp/homebrew-shotx/
cd /tmp/homebrew-shotx
git add . && git commit -m "Initial tap" && git push
```
