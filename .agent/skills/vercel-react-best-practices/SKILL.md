---
name: optimizing-react-performance
description: Applies Vercel's official React and Next.js performance optimization rules. Use when writing, reviewing, or refactoring React/Next.js code to eliminate waterfalls, optimize bundle size, and improve rendering efficiency.
---

# Vercel React Best Practices

This skill incorporates Vercel's official guidelines for performance optimization in React and Next.js applications. It covers 57 rules across 8 categories, prioritized by their impact on user experience.

## When to use this skill
- When creating new React components or Next.js pages.
- When performing code reviews for performance bottlenecks.
- When refactoring existing code to improve loading speed or responsiveness.
- When optimizing bundle size or server-side execution time.

## Rule Categories by Priority

| Priority | Category | Impact | Prefix |
|----------|----------|--------|--------|
| 1 | **Eliminating Waterfalls** | CRITICAL | `async-` |
| 2 | **Bundle Size Optimization** | CRITICAL | `bundle-` |
| 3 | **Server-Side Performance** | HIGH | `server-` |
| 4 | **Client-Side Data Fetching** | MEDIUM-HIGH | `client-` |
| 5 | **Re-render Optimization** | MEDIUM | `rerender-` |
| 6 | **Rendering Performance** | MEDIUM | `rendering-` |
| 7 | **JavaScript Performance** | LOW-MEDIUM | `js-` |
| 8 | **Advanced Patterns** | LOW | `advanced-` |

## Core Principles

### 1. Eliminating Waterfalls (CRITICAL)
Avoid sequential async operations that could be parallel.
- **async-parallel**: Use `Promise.all()` for independent operations.
- **async-defer-await**: Move `await` into specific branches where the data is actually needed.
- **async-suspense-boundaries**: Use React Suspense to stream content and allow the wrapper UI to show faster.

### 2. Bundle Size Optimization (CRITICAL)
Reduce the initial payload to improve TTI (Time to Interactive).
- **bundle-barrel-imports**: Import components and utilities directly from their files instead of using barrel files (index.ts) to enable better tree-shaking.
- **bundle-dynamic-imports**: Use `next/dynamic` or `React.lazy` for heavy components that are not visible on initial load.
- **bundle-defer-third-party**: Load non-critical scripts (analytics, chat widgets) after the main application has hydrated.

### 3. Server-Side Performance (HIGH)
Efficiently manage server-side resources and serialization.
- **server-cache-react**: Use `React.cache()` for per-request data deduplication in Next.js.
- **server-serialization**: Minimize the amount of data passed from Server Components to Client Components. Only pass primitives or necessary fields.
- **server-auth-actions**: Ensure server actions are authenticated and validated.

### 4. Re-render Optimization (MEDIUM)
Prevent unnecessary component updates.
- **rerender-memo**: Use `React.memo` for components with expensive rendering logic.
- **rerender-lazy-state-init**: Use a function for `useState` initial values if the calculation is expensive: `useState(() => expensiveFn())`.
- **rerender-derived-state**: Always derive values during render instead of putting them in `useEffect` and `useState`.

## Workflow

1.  **Identify**: Check if the code involves async data fetching, heavy imports, or frequent re-renders.
2.  **Audit**: Compare against the priority list. Focus on CRITICAL and HIGH impact categories first.
3.  **Refactor**: Apply the "Correct" patterns (e.g., swapping sequential awaits for `Promise.all`).
4.  **Verify**: Ensure the logic remains identical while performance is improved.

## Resources
- [Full Rules List](resources/rules.json)
- [Performance Checklist](resources/performance-checklist.md)
