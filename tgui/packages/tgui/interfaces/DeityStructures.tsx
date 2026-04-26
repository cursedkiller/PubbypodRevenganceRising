import { useBackend } from '../backend';
import { Button, Section, Stack, Box, Flex, ProgressBar } from '../components';
import { Window } from '../layouts';

type StructureData = {
  name: string;
  path: string;
  icon: string;
  desc: string;
  cost: number;
  materials: string;
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

  const faithColor = team_colour === 'red' ? '#ff4444' : '#4444ff';

  return (
    <Window
      title="Divine Architecture"
      width={500}
      height={600}
      theme={team_colour === 'red' ? 'syndicate' : 'ntos'}>
      <Window.Content>
        <Section
          title={
            <Flex align="center" justify="space-between" width="100%">
              <Box fontSize={1.2} bold color={faithColor}>
                Divine Structures
              </Box>
              <Box>
                <ProgressBar
                  value={faith}
                  maxValue={max_faith}
                  color={faithColor}
                  width="150px">
                  {faith}/{max_faith} Faith
                </ProgressBar>
              </Box>
            </Flex>
          }>
          <Stack vertical>
            {structures.map((structure) => (
              <Stack.Item key={structure.name}>
                <Button
                  fluid
                  disabled={faith < structure.cost}
                  onClick={() =>
                    act('build', { path: structure.path })
                  }
                  tooltip={structure.desc}>
                  <Flex align="center" justify="space-between" width="100%">
                    <Flex.Item>
                      <Box
                        as="img"
                        src={`data:image/png;base64,${structure.icon}`}
                        width="32px"
                        height="32px"
                        mr={1}
                        style={{
                          verticalAlign: 'middle',
                          imageRendering: 'pixelated',
                        }}
                      />
                    </Flex.Item>
                    <Flex.Item grow={1}>
                      <Box bold fontSize={1.1}>
                        {structure.name}
                      </Box>
                      <Box fontSize={0.8} opacity={0.7}>
                        {structure.desc}
                      </Box>
                    </Flex.Item>
                    <Flex.Item textAlign="right">
                      <Box bold color={faith >= structure.cost ? 'good' : 'bad'}>
                        {structure.cost} Faith
                      </Box>
                      <Box fontSize={0.8} opacity={0.7}>
                        {structure.materials}
                      </Box>
                    </Flex.Item>
                  </Flex>
                </Button>
              </Stack.Item>
            ))}
          </Stack>
        </Section>
        <Section>
          <Box textAlign="center" fontSize={0.8} opacity={0.5}>
            Click a structure to begin construction at your current location.
            <br />
            Structures require materials to complete - have your followers add them.
          </Box>
        </Section>
      </Window.Content>
    </Window>
  );
};
