---
name: task-board
description: Manages a `TASKS.md` file for flexible, role-agnostic collaboration between agents. Supports optional task assignment using `@AgentName`.
---

# Task Board Manager

## When to use this skill
- When the user wants to add, view, or claim tasks.
- When the user mentions "task board", "kanban", or "TASKS.md".
- When coordinating work with other agents without strict role assignments.

## Workflow
1.  **Initialize**: Run the initialization script if `TASKS.md` doesn't exist.
    -   `powershell -ExecutionPolicy Bypass -File .agent/skills/task-board/scripts/init-board.ps1`
2.  **Read & Claim**:
    -   Read `TASKS.md` to see the current state.
    -   Look for tasks in **📋 To Do**.
    -   **Priority**:
        1.  Tasks assigned to YOU (e.g., `- [ ] Task @Antigravity`).
        2.  Unassigned tasks (e.g., `- [ ] Task`).
    -   **Avoid**: Tasks assigned to others (e.g., `- [ ] Task @Terminal`).
    -   **Action**: Move the task to **🏃 In Progress** and append your name (e.g., `- [ ] Task @Antigravity`).
3.  **Update**:
    -   When a task is finished, move it to **✅ Done** and check the box (e.g., `- [x] Task @Antigravity`).

## Board Structure
-   **📌 Backlog**: Future ideas.
-   **📋 To Do**: Ready for action.
-   **🏃 In Progress**: Active work.
-   **✅ Done**: Completed work.

## Assignment Syntax
-   `@AgentName`: Assigns a task to a specific agent.
-   No tag: Free for completely anyone to pick up.

## Resources
-   `resources/template.md`: The base template for the task board.
-   `scripts/init-board.ps1`: PowerShell script to initialize the board.
