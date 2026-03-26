# GitHub Pages Hosting Setup for ZenForest Legal Pages

## What This Does
Hosts `privacy_policy.html` and `terms_of_use.html` as static pages at:
- `https://chicode-lab.github.io/Mindfulness-Game/privacy`
- `https://chicode-lab.github.io/Mindfulness-Game/terms`

These URLs are what you enter in:
- Google Play Console → Store Listing → Privacy Policy URL
- `LegalWebViewScreen` constants in Flutter
- Both HTML files' cross-links

---

## Step-by-Step: One-Time Setup

### 1. Create the `gh-pages` branch from repo root
```bash
git checkout --orphan gh-pages
git reset --hard
git commit --allow-empty -m "chore: init gh-pages branch"
git push origin gh-pages
git checkout main
```

### 2. Create the legal pages folder structure on `gh-pages`
```bash
git checkout gh-pages
mkdir -p privacy terms
```

### 3. Copy the generated HTML files
```bash
# From wherever you saved the outputs:
cp privacy_policy.html privacy/index.html
cp terms_of_use.html terms/index.html
```

### 4. Add a root index so GitHub Pages activates
```bash
echo "<html><body><p>ZenForest Legal</p></body></html>" > index.html
```

### 5. Commit and push
```bash
git add .
git commit -m "chore: add privacy policy and terms of use pages"
git push origin gh-pages
git checkout main
```

### 6. Enable GitHub Pages in repo settings
- Go to: https://github.com/ChiCode-Lab/Mindfulness-Game/settings/pages
- Source: Deploy from branch
- Branch: `gh-pages` / `/ (root)`
- Click Save
- Wait ~60 seconds for deployment

### 7. Verify live URLs
Open in browser:
- https://chicode-lab.github.io/Mindfulness-Game/privacy
- https://chicode-lab.github.io/Mindfulness-Game/terms

---

## After URLs Are Live — Update These 3 Places

### A. Flutter: `legal_webview_screen.dart`
```dart
const String _kPrivacyPolicyUrl =
    'https://chicode-lab.github.io/Mindfulness-Game/privacy';
const String _kTermsOfUseUrl =
    'https://chicode-lab.github.io/Mindfulness-Game/terms';
```

### B. Google Play Console
- App content → Privacy Policy → paste Privacy Policy URL
- Store Listing → scroll to bottom → Privacy Policy URL field

### C. HTML cross-links (already correct if you use the URLs above)
- In `privacy/index.html`: `<a href="../terms/">Terms of Use</a>`
- In `terms/index.html`: `<a href="../privacy/">Privacy Policy</a>`

---

## Before Publishing — Replace Placeholders in Both HTML Files

| Placeholder | Replace With |
|-------------|-------------|
| `privacy@chicode.lab` | Your real support/privacy email |
| `legal@chicode.lab` | Your real legal/contact email |
| `© 2026 ChiCode Lab` | Confirm entity name is correct |

---

## Notes
- The `gh-pages` branch is completely isolated — it never merges into `main`
- Future updates: just checkout `gh-pages`, edit the HTML, commit, push
- GitHub Pages is free on public repos indefinitely
- HTTPS is provided automatically by GitHub — no SSL setup needed
