---
name: transforming-flyers
description: Transforms existing marketing assets (flyers, banners, UI mockups) to match a specific brand identity using AI image manipulation. Use when the user wants to adapt an external design or template to their brand's colors, typography, and content.
---

# Branding Asset Transformation

## When to use this skill
- When the user uploads a flyer/design and asks to "make this look like our brand."
- When repurposing generic templates for specific company marketing.
- When adapting legacy assets to a new visual identity.

## Workflow
- [ ] **Analyze Source Asset**: Identify the layout structure, key elements to preserve (e.g., 3D illustrations, grid), and elements to change (colors, text).
- [ ] **Extract Brand DNA**: Consult `skills/brand-identity` or user instructions to define the target Palette, Typography, and Voice.
- [ ] **Draft Transformation Plan**: Create an implementation plan detailing the mappings (e.g., "Change Yellow -> Neon Blue", "Replace Title X with Title Y").
- [ ] **Execute AI Editing**: Use the `generate_image` tool with the `ImagePaths` parameter to edit the source layout.
- [ ] **Iterative Refinement**: Polish details (opaque fills, specific URLs, removal of hallucinations) based on preview.

## Instructions

### 1. Analysis Phase
Before generating, deeply understand the source image.
- **Layout**: Is it a grid? A hero image? A list?
- **Key Visuals**: What makes the design unique? (e.g., "3D Clay Illustration", "Geometric Mesh").
- **Constraint**: Decide what *must* stay (usually the composition/layout) and what *must* go (old branding colors).

### 2. Prompting Strategy for Transformation
When using `generate_image`, always use the **Image-to-Image** workflow:
- **ImagePaths**: `['path/to/source/image.png']` (CRITICAL: Do not start from scratch unless explicitly asked).
- **Prompt Structure**:
  1.  **Instruction**: "Edit this image. Maintain the exact layout and [Key Visuals]."
  2.  **Content Updates**: "Change Text A to Text B."
  3.  **Style Injection**: "Change background to [Brand Color]. Change accents to [Brand Accts]. Remove [Unwanted Style, e.g., neon]."
  4.  **Refinement**: "Ensure text is white and legible."

### 3. Handling Brand Specifics
- **Colors**: Use hex codes from the brand identity (e.g., `#0070F3`).
- **Logos**: If you cannot render the exact logo file, instruct the AI to render the *Brand Name* in the *Brand Font/Gradient*.
- **URLs/QR Codes**: You can request "add a QR code" or "update URL to [url]".

### 4. Common Pitfalls & Fixes
- **"The text is gibberish"**: AI struggles with small text. Keep text requests large/headline-focused. For body text, assume it might need post-processing or accept placeholders.
- **"It changed the layout completely"**: meaningfuly emphasize "Maintain the exact layout" in the prompt.
- **"It looks too neon/busy"**: Explicitly prompt negative constraints: "Remove neon glow", "Make background matte/clean."

## Resources
- Uses `generate_image` tool.
- Relies on `brand-identity` skill for target data.
