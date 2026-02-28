---
name: context-bridge
description: Manages a `CONTEXT.md` file to facilitate collaboration between multiple AI agents (e.g., Antigravity and a terminal agent). Use when the user mentions "bridge file", "context file", or "hand off to terminal agent".
---

# Context Bridge Manager

## When to use this skill
- When the user wants to hand off a task to a terminal-based agent (like OpenCode or ClaudeCode).
- When the user asks to "update the context" or "prepare for handoff".
- When starting a new session and needing to restore context from a file.

## Workflow
1.  **Initialize**: Run the initialization script to create the `CONTEXT.md` file if it doesn't exist.
    -   `powershell -ExecutionPolicy Bypass -File .agent/skills/context-bridge/scripts/init-context.ps1`
2.  **Update**:
    -   Read `CONTEXT.md`.
    -   Update the "Current Status" and "Current Task".
    -   Keep "Architecture Notes" concise.
3.  **Handoff**: Provide detailed instructions in the "Current Task" section.

## Instructions
-   Always check for `CONTEXT.md` before starting work.
-   If the file exists, prioritize its instructions over general knowledge.
-   When finishing a turn, update the "Current Status" to reflect what was done.

## Resources
-   `resources/template.md`: The base template for the context file.
-   `scripts/init-context.ps1`: PowerShell script to initialize the file.
