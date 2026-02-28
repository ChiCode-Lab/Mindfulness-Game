---
name: troubleshooting-applications
description: Provides a systematic approach to identifying, diagnosing, and resolving application errors and performance issues. Use when debugging code, analyzing logs, or fixing production incidents across various programming languages.
---

# Troubleshooting Applications

A comprehensive guide and workflow for systematically fixing application issues, leveraging robust error-handling patterns to ensure long-term stability.

## When to Use This Skill

- Debugging production issues or crashes
- Analyzing logs to find root causes of failures
- Fixing bugs in existing features
- Implementing error resilience in unstable systems
- Applying language-specific error handling patterns
- Improving application reliability and fault tolerance

## Workflow: Systematic Troubleshooting

Follow this checklist when tasked with fixing an application issue:

- [ ] **Gather Information**: collect error messages, stack traces, and environment details.
- [ ] **Reproduce the Issue**: Create a minimal reproduction case or test script.
- [ ] **Analyze Root Cause**: Use the "Core Concepts" and "Language-Specific Patterns" below to categorize the error.
- [ ] **Select a Pattern**: Decide on a recovery strategy (Retry, Circuit Breaker, Fallback, etc.).
- [ ] **Implement the Fix**: Apply the fix and any necessary error handling improvements.
- [ ] **Verify and Test**: Confirm the fix works and doesn't introduce regressions.
- [ ] **Document/Log**: Ensure the error is logged meaningfully for future occurrence.

## Core Concepts

### 1. Error Handling Philosophies
- **Exceptions**: Use for truly exceptional, unexpected conditions (e.g., DB down).
- **Result Types**: Use for expected failures (e.g., validation errors, 404s).
- **Panics/Crashes**: Use for unrecoverable logic bugs that make state inconsistent.

### 2. Error Categories
- **Recoverable**: Network blips, user input, rate limits. Strategy: Retry or Fallback.
- **Unrecoverable**: Memory exhaustion, hardware failure. Strategy: Graceful Shutdown.

---

## Language-Specific Patterns

### Python Error Handling
```python
class ApplicationError(Exception):
    def __init__(self, message: str, code: str = None, details: dict = None):
        super().__init__(message)
        self.code = code
        self.details = details or {}

@contextmanager
def database_transaction(session):
    try:
        yield session
        session.commit()
    except Exception:
        session.rollback()
        raise
    finally:
        session.close()
```

### TypeScript/JavaScript Error Handling
```typescript
class ApplicationError extends Error {
  constructor(public message: string, public code: string, public statusCode: number = 500) {
    super(message);
    this.name = this.constructor.name;
  }
}

// Result Type for explicit handling
type Result<T, E = Error> = { ok: true; value: T } | { ok: false; error: E };
```

### Rust Error Handling
```rust
fn read_file(path: &str) -> Result<String, io::Error> {
    let mut file = File::open(path)?; // ? operator propagates errors
    let mut contents = String::new();
    file.read_to_string(&mut contents)?;
    Ok(contents)
}
```

### Go Error Handling
```go
func getUser(id string) (*User, error) {
    user, err := db.QueryUser(id)
    if err != nil {
        return nil, fmt.Errorf("failed to query user: %w", err)
    }
    return user, nil
}
```

---

## Universal Patterns

### Pattern 1: Circuit Breaker
Prevents cascading failures by stopping calls to a failing service. See `CircuitBreaker` logic for implementation details.

### Pattern 2: Graceful Degradation
Always provide a fallback. If the cache is down, go to the DB. If the DB is down, return a default/cached value if possible.

### Pattern 3: Error Aggregation
Collect all validation errors before failing, rather than making the user fix things one by one.

## Best Practices
1. **Fail Fast**: Validate early.
2. **Preserve Context**: Keep stack traces and metadata.
3. **Meaningful Messages**: "User not found (ID: 123)" vs "Error".
4. **Log Appropriately**: Don't swallow errors; log them where they can be acted upon.
5. **Clean Up**: Always use `try-finally` or equivalent for resources.

## Resources
- [Error Handling Patterns In-Depth](resources/error-patterns-detailed.md)
- [Troubleshooting Checklist](resources/checklist.md)
