import { Composition } from 'remotion';
import { HelloWorld } from './HelloWorld';
import { MarketingSocial } from './MarketingSocial';

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
      <Composition
        id="MarketingSocial"
        component={MarketingSocial}
        durationInFrames={300}
        fps={30}
        width={1920}
        height={1080}
      />
    </>
  );
};
