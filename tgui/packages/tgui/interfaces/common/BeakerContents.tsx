import type { BooleanLike } from 'common/react';
import { AnimatedNumber, Box } from 'tgui/components';

export type BeakerProps = { name: string; volume: number }[];

export const BeakerContents = (props: {
  readonly beakerLoaded: BooleanLike;
  readonly beakerContents: BeakerProps;
}) => {
  const { beakerLoaded, beakerContents } = props;
  return (
    <Box>
      {(!beakerLoaded && <Box color="label">No beaker loaded.</Box>) ||
        (beakerContents.length === 0 && (
          <Box color="label">Beaker is empty.</Box>
        ))}
      {beakerContents.map((chemical) => (
        <Box key={chemical.name} color="label">
          <AnimatedNumber initial={0} value={chemical.volume} />
          {' units of ' + chemical.name}
        </Box>
      ))}
    </Box>
  );
};
