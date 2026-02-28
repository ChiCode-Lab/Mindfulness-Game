import React from 'react';
import { AbsoluteFill, interpolate, spring, useCurrentFrame, useVideoConfig } from 'remotion';

const BRAND_COLORS = {
  background: '#050A0F',
  primary: '#0070F3',
  secondary: '#00E6C8',
  white: '#FFFFFF',
};

export const MarketingSocial: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps, width, height } = useVideoConfig();

  // Animation Utilities
  const spr = (startFrame: number, duration: number = 30) => 
    spring({ frame: frame - startFrame, fps, config: { damping: 10, stiffness: 100 } });

  // Slide 1: Logo Reveal (0-3s)
  const logoScale = interpolate(frame, [0, 40], [0.8, 1], { extrapolateRight: 'clamp' });
  const logoOpacity = interpolate(frame, [0, 30], [0, 1], { extrapolateRight: 'clamp' });
  const logoBlur = interpolate(frame, [0, 30], [20, 0], { extrapolateRight: 'clamp' });

  // Slide 2: Web & App (3.5-6.5s)
  const slide2Start = 100;
  const slide2Prog = spr(slide2Start);
  const slide2Opacity = interpolate(frame, [slide2Start, slide2Start + 15, slide2Start + 80, slide2Start + 95], [0, 1, 1, 0], { extrapolateRight: 'clamp' });

  // Slide 3: Tagline (7-10s)
  const slide3Start = 200;
  const slide3Prog = spr(slide3Start);
  const slide3Opacity = interpolate(frame, [slide3Start, slide3Start + 15, 290, 300], [0, 1, 1, 0], { extrapolateRight: 'clamp' });

  return (
    <AbsoluteFill style={{ backgroundColor: BRAND_COLORS.background, fontFamily: 'sans-serif' }}>
      
      {/* Background Animated Gradient Glow */}
      <div style={{
        position: 'absolute',
        width: '100%',
        height: '100%',
        background: `radial-gradient(circle at center, ${BRAND_COLORS.primary}22 0%, transparent 70%)`,
        opacity: interpolate(Math.sin(frame / 20), [-1, 1], [0.3, 0.7]),
      }} />

      {/* Slide 1: Logo */}
      {frame < 110 && (
        <AbsoluteFill style={{ justifyContent: 'center', alignItems: 'center', opacity: interpolate(frame, [95, 110], [1, 0]) }}>
          <div style={{ 
            transform: `scale(${logoScale})`, 
            opacity: logoOpacity, 
            filter: `blur(${logoBlur}px)`,
            textAlign: 'center'
          }}>
            <h1 style={{ 
              fontSize: 160, 
              fontWeight: 800, 
              margin: 0, 
              background: `linear-gradient(to right, ${BRAND_COLORS.primary}, ${BRAND_COLORS.secondary})`,
              WebkitBackgroundClip: 'text',
              WebkitTextFillColor: 'transparent',
              textShadow: '0 0 40px rgba(0, 112, 243, 0.5)'
            }}>
              ChiCode
            </h1>
            <p style={{ color: BRAND_COLORS.white, fontSize: 40, letterSpacing: 8, marginTop: 20, opacity: 0.8 }}>
              INNOVATION BY DESIGN
            </p>
          </div>
        </AbsoluteFill>
      )}

      {/* Slide 2: Services */}
      {(frame >= 100 && frame < 210) && (
        <AbsoluteFill style={{ justifyContent: 'center', alignItems: 'center', opacity: slide2Opacity }}>
          <div style={{ textAlign: 'center' }}>
            <h2 style={{ color: BRAND_COLORS.secondary, fontSize: 80, fontWeight: 700 }}>
              Web & App Development
            </h2>
            <div style={{ 
              height: 4, 
              width: interpolate(frame - slide2Start, [0, 40], [0, 600], { extrapolateRight: 'clamp' }), 
              background: BRAND_COLORS.primary,
              margin: '20px auto',
              borderRadius: 2
            }} />
            <p style={{ color: BRAND_COLORS.white, fontSize: 45, opacity: 0.9 }}>
              Crafting Digital Excellence
            </p>
          </div>
        </AbsoluteFill>
      )}

      {/* Slide 3: Final CTA */}
      {frame >= 200 && (
        <AbsoluteFill style={{ justifyContent: 'center', alignItems: 'center', opacity: slide3Opacity }}>
          <div style={{ textAlign: 'center' }}>
            <h2 style={{ 
              fontSize: 120, 
              fontWeight: 800, 
              background: `linear-gradient(to right, ${BRAND_COLORS.primary}, ${BRAND_COLORS.secondary})`,
              WebkitBackgroundClip: 'text',
              WebkitTextFillColor: 'transparent',
              marginBottom: 40
            }}>
              Let's Build Together
            </h2>
            <div style={{
              padding: '20px 60px',
              borderRadius: 100,
              border: `2px solid ${BRAND_COLORS.secondary}`,
              display: 'inline-block',
              color: BRAND_COLORS.white,
              fontSize: 40,
              fontWeight: 600,
              boxShadow: '0 0 20px rgba(0, 230, 200, 0.3)'
            }}>
              chicodelabs@gmail.com
            </div>
          </div>
        </AbsoluteFill>
      )}

    </AbsoluteFill>
  );
};
