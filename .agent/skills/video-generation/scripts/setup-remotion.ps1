# setup-remotion.ps1
# This script initializes the Remotion environment for the project.

$RemotionDir = Join-Path $PSScriptRoot "../../remotion-assets"
if (-not (Test-Path $RemotionDir)) {
    New-Item -ItemType Directory -Path $RemotionDir -Force
}

Set-Location $RemotionDir

# Initialize npm if package.json doesn't exist
if (-not (Test-Path "package.json")) {
    & npm.cmd init -y
}

Write-Host "Installing Remotion dependencies..."
& npm.cmd install remotion @remotion/cli react react-dom @types/react @types/react-dom typescript

Write-Host "Installing FFMPEG..."
& npx.cmd -y @remotion/cli ffmpeg install

Write-Host "Creating base project structure..."
if (-not (Test-Path "src")) {
    New-Item -ItemType Directory -Path "src" -Force
}

# Create Root.tsx
$RootContent = @"
import { Composition } from 'remotion';
import { HelloWorld } from './HelloWorld';

export const RemotionRoot: React.FC = () => {
  return (
    <>
      <Composition
        id="HelloWorld"
        component={HelloWorld}
        durationInFrames={150}
        fps={30}
        width={1920}
        height={1080}
      />
    </>
  );
};
"@
$RootContent | Out-File -FilePath "src/Root.tsx" -Encoding utf8

# Create HelloWorld.tsx
$HelloContent = @"
import { AbsoluteFill, interpolate, useCurrentFrame, useVideoConfig } from 'remotion';

export const HelloWorld: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const opacity = interpolate(frame, [0, 30], [0, 1], { extrapolateRight: 'clamp' });
  
  return (
    <AbsoluteFill style={{ 
      backgroundColor: '#050A0F', 
      justifyContent: 'center', 
      alignItems: 'center',
      color: 'white',
      fontFamily: 'sans-serif'
    }}>
      <h1 style={{ color: '#0070F3', fontSize: 120, opacity }}>
        ChiCode
      </h1>
      <div style={{ 
        position: 'absolute', 
        bottom: 50, 
        color: '#00E6C8', 
        fontSize: 40,
        opacity: interpolate(frame, [30, 60], [0, 1])
      }}>
        Video Generation Ready
      </div>
    </AbsoluteFill>
  );
};
"@
$HelloContent | Out-File -FilePath "src/HelloWorld.tsx" -Encoding utf8

# Create index.ts
$IndexContent = @"
import { registerRoot } from 'remotion';
import { RemotionRoot } from './Root';

registerRoot(RemotionRoot);
"@
$IndexContent | Out-File -FilePath "src/index.ts" -Encoding utf8

Write-Host "Setup complete! You can now render videos."
Write-Host "Try: npx.cmd -y @remotion/cli render src/index.ts HelloWorld out/video.mp4"
