# Troubleshooting Checklist

Use this checklist to maintain a consistent process when debugging and fixing application issues.

## 1. Discovery & Analysis
- [ ] Record the exact error message and stack trace.
- [ ] Identify the environment (local, staging, production).
- [ ] Determine if the issue is a regression (was it working before?).
- [ ] Check logs (application logs, system logs, access logs).
- [ ] Check metrics (CPU, Memory, Network spikes).

## 2. Reproduction
- [ ] Define the exact steps to reproduce.
- [ ] Identify the minimal required state for reproduction.
- [ ] Set up a local environment that mirrors the issue.
- [ ] If intermittent, try to increase load or stress test to trigger.

## 3. Diagnosis
- [ ] Is it an application bug (logic)?
- [ ] Is it an infrastructure issue (timeout, connection)?
- [ ] Is it a data issue (missing field, corrupted DB)?
- [ ] Is it an external dependency issue (API down, DNS)?

## 4. Implementation & Fix
- [ ] Write a test case that fails because of the bug.
- [ ] Implement the fix.
- [ ] Ensure the test case now passes.
- [ ] Review for side effects.

## 5. Verification & Prevention
- [ ] Verify fix in staging/QA.
- [ ] Add monitoring/alerts for this specific error.
- [ ] Improve log context for this area of the code.
- [ ] Document the fix in the internal wiki or ticket system.
