import { useBackend } from '../backend';
import {
  Button,
  Stack,
  Box,
  Flex,
  ProgressBar,
  Divider,
  Icon,
} from '../components';
import { Window } from '../layouts';
import { DmIcon } from 'tgui-core/components';

type StructureData = {
  name: string;
  path: string;
  icon: string;
  icon_state: string;
  desc: string;
  cost: number;
  materials: string;
  free: number;
};

type DeityData = {
  faith: number;
  max_faith: number;
  team_colour: string;
  structures: StructureData[];
};

export const DeityStructures = (props) => {
  const { act, data } = useBackend<DeityData>();
  const { faith, max_faith, team_colour, structures } = data;

  const goldColor = '#d4af37';
  const faithColor = team_colour === 'red' ? '#cc4444' : '#4488cc';
  const borderColor = team_colour === 'red' ? '#8b2020' : '#20408b';
  const holyBg = team_colour === 'red' ? '#2a1010' : '#10102a';

  return (
    <Window
      title="Divine Architecture"
      width={520}
      height={640}
      theme={team_colour === 'red' ? 'syndicate' : 'ntos'}>
      <Window.Content scrollable>
        <Box textAlign="center" mb={1}>
          <Box
            fontSize={2.2}
            bold
            color={goldColor}
            fontFamily="serif"
            letterSpacing={2}>
            DIVINE ARCHITECTURE
          </Box>
          <Box fontSize={0.9} color={goldColor} opacity={0.7} mt={0.5}>
            Manifest the will of the divine into sacred form
          </Box>
        </Box>
        <Box
          backgroundColor={holyBg}
          p={1.5}
          mb={1}
          style={{
            borderRadius: '4px',
            border: `1px solid ${borderColor}`,
          }}>
          <Flex align="center" justify="space-between">
            <Box fontSize={1} bold color={goldColor}>
              Divine Essence
            </Box>
            <Box width="60%">
              <ProgressBar
                value={faith}
                maxValue={max_faith}
                color={faithColor}>
                <Box bold fontSize={1.1}>
                  {faith} / {max_faith}
                </Box>
              </ProgressBar>
            </Box>
          </Flex>
        </Box>
        <Stack vertical>
          {structures.map((structure) => {
            const isFree = !!structure.free;
            const canAfford = isFree || faith >= structure.cost;
            return (
              <Stack.Item key={structure.name}>
                <Button
                  fluid
                  disabled={!canAfford}
                  onClick={() =>
                    act('build', { path: structure.path })
                  }
                  tooltip={structure.desc}
                  backgroundColor={isFree ? '#0a1a0a' : '#111118'}
                  style={{
                    borderLeft: `4px solid ${isFree ? '#2d8b2d' : goldColor}`,
                    padding: '10px',
                    minHeight: '64px',
                    borderBottom: '1px solid #222233',
                  }}>
                  <Flex align="center" width="100%">
                    <Flex.Item mr={1.5}>
                      <Box
                        backgroundColor={holyBg}
                        style={{
                          borderRadius: '4px',
                          border: `2px solid ${borderColor}`,
                          padding: '2px',
                        }}>
                        <DmIcon
                          icon={structure.icon}
                          icon_state={structure.icon_state}
                          fallback={
                            <Icon
                              name="spinner"
                              spin
                              fontSize="30px"
                            />
                          }
                          width="40px"
                          style={{
                            imageRendering: 'pixelated',
                          }}
                        />
                      </Box>
                    </Flex.Item>
                    <Flex.Item grow={1}>
                      <Flex align="center" gap={1}>
                        <Box
                          bold
                          fontSize={1.1}
                          color={isFree ? '#5ab45a' : goldColor}>
                          {structure.name}
                        </Box>
                        {isFree && (
                          <Box
                            fontSize={0.65}
                            backgroundColor="#2d8b2d"
                            color="white"
                            px={0.8}
                            style={{ borderRadius: '2px' }}>
                            FIRST BLESSING
                          </Box>
                        )}
                      </Flex>
                      <Box
                        fontSize={0.82}
                        opacity={0.7}
                        mt={0.3}
                        fontStyle="italic">
                        &ldquo;{structure.desc}&rdquo;
                      </Box>
                    </Flex.Item>
                    <Flex.Item textAlign="right" minWidth="120px">
                      <Box
                        bold
                        fontSize={1.1}
                        color={
                          isFree
                            ? '#5ab45a'
                            : faith >= structure.cost
                              ? goldColor
                              : '#884444'
                        }>
                        {isFree
                          ? 'BLESSED'
                          : structure.cost + ' Faith'}
                      </Box>
                      <Box fontSize={0.75} opacity={0.5} mt={0.2}>
                        {structure.materials}
                      </Box>
                    </Flex.Item>
                  </Flex>
                </Button>
              </Stack.Item>
            );
          })}
        </Stack>
        <Divider mt={1} />
        <Box
          textAlign="center"
          fontSize={0.8}
          opacity={0.35}
          mt={1}
          fontStyle="italic">
          Speak the word, and it shall be done.
          <br />
          Your faithful shall complete these sacred works.
        </Box>
      </Window.Content>
    </Window>
  );
};
