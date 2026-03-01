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

After implementing, you MUST take a screenshot of the ACTUAL feature you just built. Because this is a Flutter Web app without URL routing, follow this exact procedure:

1. **Temporarily modify `main.dart`**: Change the `home:` property of `MaterialApp` to directly render the new widget/screen you are working on (e.g. `ForestScreen` instead of `DashboardScreen`).
2. Start the local server: `python3 -m http.server 8080` (or `flutter run -d chrome --web-port 8080`)
3. Use Playwright to navigate to `http://localhost:8080` and wait for the canvas to load.
4. Take a screenshot and save it as: `screenshots/[task-id].png`
5. **Revert your temporary change** to `main.dart` so it isn't committed.

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