# React Performance Optimization Checklist

Follow this checklist to ensure your React and Next.js applications are optimized according to Vercel's best practices.

## 1. Data Fetching & Waterfalls (CRITICAL)
- [ ] Are all independent async operations wrapped in `Promise.all()`?
- [ ] Have you moved `await` calls as close as possible to the code that uses the data?
- [ ] Are you using `Suspense` boundaries to stream non-critical UI components?
- [ ] In API routes, do you start promises early and only `await` them when needed?

## 2. Bundle Size (CRITICAL)
- [ ] Are you importing directly from modules instead of using barrel files (`import { X } from '@/components'` -> `import X from '@/components/X'`)?
- [ ] Are heavy components (charts, editors, etc.) loaded using `next/dynamic` or `React.lazy`?
- [ ] Are third-party scripts (analytics, chat) deferred until after hydration?
- [ ] Have you removed or replaced large dependencies with smaller alternatives (e.g., date-fns instead of moment)?

## 3. Server-Side Optimization (HIGH)
- [ ] Is `React.cache()` used to deduplicate per-request data fetching?
- [ ] Are you only passing essential primitive data from Server to Client components?
- [ ] Are all Server Actions properly authenticated?
- [ ] Are you using the `after()` function (for Next.js) for non-blocking operations like logging?

## 4. Rendering & Re-renders (MEDIUM)
- [ ] Are expensive calculations wrapped in `useMemo`?
- [ ] Is `React.memo` applied to components that receive stable props but re-render often?
- [ ] Are default non-primitive props (like empty arrays or objects) hoisted outside the component?
- [ ] Are you using functional state updates (`setCount(c => c + 1)`) to avoid dependency array issues?
- [ ] is `startTransition` used for non-urgent state updates to keep the UI responsive?

## 5. General JavaScript (LOW-MEDIUM)
- [ ] Are you using `Map` or `Set` for O(1) lookups instead of searching through arrays?
- [ ] Have you combined multiple `.filter().map()` calls into a single loop where appropriate?
- [ ] Are expensive function results cached at the module level if they are pure?
- [ ] Are `RegExp` objects defined outside of loops?
