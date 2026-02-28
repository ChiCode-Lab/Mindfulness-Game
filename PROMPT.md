@mindfulness_app/docs/activity.md @mindfulness_app/docs/zen-forest-features.json

We are building the Zen Forest and Legacy Forest additions to the mindfulness Flutter app.

---

## STEP 1 — Read Context

First, read `mindfulness_app/docs/activity.md` to understand what was recently accomplished and what state the project is in.

---

## STEP 2 — Choose ONE Task

Open `mindfulness_app/docs/zen-forest-features.json` and find the **single highest-priority task** where `"passes": false`. That is your ONE task for this session.

Do NOT work on more than one task.

---

## STEP 3 — Implement the Task

Implement the chosen task in the Flutter codebase. Follow the `steps` array listed for that task in the JSON file.

---

## STEP 4 — Verify with Screenshot

After implementing, build/serve the app and take a screenshot:

1. Start the Flutter web build or a local HTTP server if a web build exists:
   - Try: `python3 -m http.server 8080` (or another port if taken)
   - Or: `flutter run -d chrome --web-port 8080`
2. Take a screenshot using Playwright and save it as:
   `screenshots/[task-id].png`
   where `[task-id]` matches the `"id"` field in the JSON.

---

## STEP 5 — Update Progress Files

1. **Update `mindfulness_app/docs/zen-forest-features.json`**: Change that task's `"passes": false` to `"passes": true`.
2. **Append to `mindfulness_app/docs/activity.md`**: Add a dated entry describing what was changed and the screenshot filename.

---

## STEP 6 — Git Commit

Make a single, focused git commit for this task only:
```
git add -A
git commit -m "feat: [task-id] - [short description]"
```

Do NOT `git init`, do NOT change remotes, do NOT push.

---

## STEP 7 — Check Completion

After updating the JSON, check if ALL tasks now have `"passes": true`.

- If YES → output exactly: `<promise>COMPLETE</promise>`
- If NO → stop and wait for the next iteration.

**ONLY WORK ON A SINGLE TASK PER RUN.**