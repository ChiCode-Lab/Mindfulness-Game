---
name: video-generation
description: Generates high-quality videos using Remotion and React. Use when the user asks to "make a video", "render a clip", or mentions Remotion.
---

# Video Generation with Remotion

You are an expert at creating programmatic videos using Remotion (React-based video framework). You can generate MP4 files, GIFs, or frames by writing React components and rendering them.

## When to use this skill
- When the user asks to "make a video" or "create a clip".
- When the user wants to visualize data or code as an animation.
- When the user mentions "Remotion".

## Prerequisites
- Node.js installed.
- Remotion engine setup (located in `resources/remotion-engine`).
- FFMPEG installed via Remotion.

## Workflow

1.  **Define the Video**: Create or modify a React component in `resources/remotion-engine/src/` (e.g., `HelloWorld.tsx`).
2.  **Register Composition**: Add the composition to `resources/remotion-engine/src/Root.tsx`.
3.  **Render**: Run the render command to produce the video file.
4.  **Show Outcome**: Provide the path to the generated video.

## Rendering
```powershell
# From the .agent/skills/video-generation/resources/remotion-engine directory
.\node_modules\.bin\remotion.cmd render src/index.ts HelloWorld out/video.mp4
```

## Best Practices
- Use `useCurrentFrame` and `interpolate` for animations.
- Keep duration in mind (usually 30-60 fps).
- Use `AbsoluteFill` for layouts.
- Follow **brand-identity** tokens (Colors: `#0070F3`, `#00E6C8`, `#050A0F`).

## Current Engine Location
`c:\Users\user\Desktop\ChiCode\Skill Master\.agent\skills\video-generation\resources\remotion-engine`
