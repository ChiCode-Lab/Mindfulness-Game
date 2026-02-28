---
name: planning
description: Creates granular, step-by-step "precision engineering" plans for technical tasks. Use after a design is approved to break down complex work into manageable, test-driven implementation steps.
---

# Planning

## When to use this skill
- When a design from the `brainstorming` skill is ready for implementation.
- When you have a clear spec and need to execute it with "Technical Integrity."
- Before writing any code for multi-step features.

## Workflow
- [ ] **Context Alignment**: Review approved design and current codebase.
- [ ] **Bite-Sized Breakdown**: Create tasks that take 2-5 minutes each.
- [ ] **TDD Integration**: Ensure every task includes a failing test step.
- [ ] **Plan Documentation**: Save to `docs/plans/YYYY-MM-DD-<feature-name>-plan.md`.
- [ ] **Execution Choice**: Offer subagent-driven or batch execution.

## Instructions

### 1. Plan Structure
Every plan MUST follow this high-performance format:

```markdown
# [Feature Name] Implementation Plan

**Goal:** [One sentence describing the transformation this builds]
**Architecture Fusion:** [Summary of how this integrates into the ecosystem]
**Scalability Strategy:** [Tech stack and performance considerations]

---

### Task N: [Component Name]
**Engineering Paths:**
- Create: `exact/path/to/new_file.js`
- Leverage: `exact/path/to/existing.py:lines`
- Test: `tests/path/to/test_file.js`

**Step 1: Red Stage** (Write failing test)
[Code block with the test]

**Step 2: Verification**
Run `[test command]` and confirm failure.

**Step 3: Green Stage** (Minimal implementation)
[Code block with the fix]

**Step 4: Validation**
Run `[test command]` and confirm "Precision Success."

**Step 5: Commit**
`git add ... && git commit -m "feat: [concise description]"`
```

### 2. Principles of Integrity
- **YAGNI**: No speculative code.
- **TDD**: Write the test first, always.
- **DRY**: Leverage existing "Smart Tech" utilities.
- **Exactness**: Always use exact file paths and ranges.

## Resources
- Use `brand-identity` for technical stack and naming conventions.
