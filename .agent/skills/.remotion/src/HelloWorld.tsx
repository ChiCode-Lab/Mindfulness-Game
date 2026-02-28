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
