# Preferred Tech Stack & Implementation Rules

When generating code or UI components for this brand, you **MUST** strictly adhere to the following technology choices.

## Core Stack
* **Framework:** React (TypeScript preferred)
* **Styling Engine:** Tailwind CSS (Mandatory.)
* **Component Library:** shadcn/ui
* **Icons:** Lucide React

## Implementation Guidelines

### 1. Visual Aesthetic: "Modern Futuristic Dark Mode"
* **Default Theme:** Dark mode is the primary experience. Use `bg-[#050A0F]` for background and `text-white` for primary text.
* **Gradients:** Use the primary gradient (`from-[#0070F3] to-[#00E6C8]`) for high-impact elements like call-to-action buttons, logic highlights, and main headings.
* **Glow Effects:** Apply subtle glows using shadow utilities (e.g., `shadow-[0_0_20px_rgba(0,112,243,0.4)]`) to create a "tech" feel.

### 2. Tailwind Usage
* Use utility classes directly in JSX.
* Favor hardcoded hex values from `design-tokens.json` if Tailwind config is not available, or use the project's color tokens if they exist.
* **Pill Buttons:** Most primary buttons should use `rounded-full`.

### 3. Component Patterns
* **Cards:** Use `bg-[#050A0F]/50` with a subtle border and high border radius (`rounded-2xl`).
* **Forms:** Maintain clean, minimalist inputs with focus states that use the primary blue color.

### 4. Forbidden Patterns
* Do NOT use standard Bootstrap or light-mode-first designs.
* Do NOT use generic red/blue/green colors. Stick to the ChiCode palette.

