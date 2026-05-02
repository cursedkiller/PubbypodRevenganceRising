import { useBackend } from '../backend';
import { Button, Stack, Box, Flex, Section, NoticeBox } from '../components';
import { Window } from '../layouts';
import { DmIcon } from 'tgui-core/components';

const GRID_SIZE = 16;

type ScrollType = {
  name: string;
  desc: string;
  icon: string;
  grid_size: number;
  faith_cost: number;
};

type ScribingData = {
  team_colour: string;
  scroll_types: ScrollType[];
};

export const ScribingTable = (props) => {
  const { act, data } = useBackend<ScribingData>();
  const { team_colour, scroll_types } = data;

  const [selectedScroll, setSelectedScroll] = React.useState<ScrollType | null>(null);
  const [grid, setGrid] = React.useState<boolean[][]>(
    Array(GRID_SIZE).fill(null).map(() => Array(GRID_SIZE).fill(false))
  );
  const [isDrawing, setIsDrawing] = React.useState(false);
  const [paintMode, setPaintMode] = React.useState<'paint' | 'erase'>('paint');

  const gridPixelSize = 20;
  const canvasSize = GRID_SIZE * gridPixelSize;

  const handlePixelClick = (x: number, y: number) => {
    const newGrid = grid.map((row) => [...row]);
    newGrid[x][y] = paintMode === 'paint' ? true : false;
    setGrid(newGrid);
  };

  const handleMouseDown = (x: number, y: number) => {
    setIsDrawing(true);
    handlePixelClick(x, y);
  };

  const handleMouseEnter = (x: number, y: number) => {
    if (isDrawing) {
      handlePixelClick(x, y);
    }
  };

  const handleMouseUp = () => {
    setIsDrawing(false);
  };

  const clearCanvas = () => {
    setGrid(Array(GRID_SIZE).fill(null).map(() => Array(GRID_SIZE).fill(false)));
  };

  const handleFinalize = () => {
    if (!selectedScroll) return;
    const pixels = [];
    for (let x = 0; x < GRID_SIZE; x++) {
      for (let y = 0; y < GRID_SIZE; y++) {
        if (grid[x][y]) {
          pixels.push({ x, y });
        }
      }
    }
    act('craft', { type: selectedScroll.name, pixels });
    clearCanvas();
    setSelectedScroll(null);
  };

  const goldColor = '#d4af37';
  const faithColor = team_colour === 'red' ? '#cc4444' : '#4488cc';
  const borderColor = team_colour === 'red' ? '#8b2020' : '#20408b';
  const holyBg = team_colour === 'red' ? '#2a1010' : '#10102a';
  const paintedColor = team_colour === 'red' ? '#ff4444' : '#4488ff';

  return (
    <Window title="Divine Scribing Table" width={520} height={640} theme={team_colour === 'red' ? 'syndicate' : 'ntos'}>
      <Window.Content
        scrollable
        onMouseUp={handleMouseUp}
        onMouseLeave={handleMouseUp}>
        <Box textAlign="center" mb={1}>
          <Box fontSize={2.2} bold color={goldColor} fontFamily="serif" letterSpacing={2}>
            DIVINE SCRIBING
          </Box>
          <Box fontSize={0.9} color={goldColor} opacity={0.7} mt={0.5}>
            Inscribe sacred runes to craft divine scrolls
          </Box>
        </Box>

        {!selectedScroll ? (
          // SCROLL TYPE SELECTION
          <Section title="Select Scroll Type" textAlign="center">
            <Stack vertical>
              {scroll_types.map((scroll) => (
                <Stack.Item key={scroll.name}>
                  <Button
                    fluid
                    onClick={() => {
                      setSelectedScroll(scroll);
                      const size = scroll.grid_size || GRID_SIZE;
                      setGrid(
                        Array(size).fill(null).map(() => Array(size).fill(false))
                      );
                    }}
                    backgroundColor="#111118"
                    style={{
                      borderLeft: `4px solid ${goldColor}`,
                      padding: '10px',
                      minHeight: '48px',
                    }}>
                    <Flex align="center" width="100%">
                      <Flex.Item mr={1.5}>
                        <Box backgroundColor={holyBg} style={{ borderRadius: '4px', border: `2px solid ${borderColor}`, padding: '2px' }}>
                          <DmIcon
                            icon="icons/obj/hand_of_god_structures.dmi"
                            icon_state={scroll.icon}
                            width="32px"
                            style={{ imageRendering: 'pixelated' }}
                          />
                        </Box>
                      </Flex.Item>
                      <Flex.Item grow={1}>
                        <Box bold fontSize={1.1} color={goldColor}>
                          {scroll.name}
                        </Box>
                        <Box fontSize={0.82} opacity={0.7} mt={0.3} fontStyle="italic">
                          &ldquo;{scroll.desc}&rdquo;
                        </Box>
                      </Flex.Item>
                      <Flex.Item textAlign="right" minWidth="80px">
                        <Box bold color={goldColor}>
                          {scroll.faith_cost} Faith
                        </Box>
                      </Flex.Item>
                    </Flex>
                  </Button>
                </Stack.Item>
              ))}
            </Stack>
          </Section>
        ) : (
          // CANVAS DRAWING MODE
          <>
            <Box mb={1}>
              <Button icon="arrow-left" onClick={() => setSelectedScroll(null)}>
                Back to Selection
              </Button>
              <Box ml={1} fontSize={1.2} color={goldColor} inline>
                Drawing: {selectedScroll.name}
              </Box>
            </Box>

            <Box mb={1}>
              <Flex gap={1}>
                <Flex.Item>
                  <Button
                    icon="paint-brush"
                    selected={paintMode === 'paint'}
                    onClick={() => setPaintMode('paint')}
                    backgroundColor={paintMode === 'paint' ? '#334433' : undefined}>
                    Paint
                  </Button>
                </Flex.Item>
                <Flex.Item>
                  <Button
                    icon="eraser"
                    selected={paintMode === 'erase'}
                    onClick={() => setPaintMode('erase')}
                    backgroundColor={paintMode === 'erase' ? '#443333' : undefined}>
                    Erase
                  </Button>
                </Flex.Item>
                <Flex.Item>
                  <Button icon="trash" onClick={clearCanvas}>
                    Clear
                  </Button>
                </Flex.Item>
              </Flex>
            </Box>

            <Box textAlign="center" mb={1}>
              <Box
                style={{
                  display: 'inline-block',
                  border: `2px solid ${goldColor}`,
                  backgroundColor: '#1a1a2a',
                  padding: '4px',
                  cursor: 'crosshair',
                  userSelect: 'none',
                }}>
                {grid.map((row, x) => (
                  <Box key={x} style={{ display: 'flex' }}>
                    {row.map((pixel, y) => (
                      <Box
                        key={`${x}-${y}`}
                        onMouseDown={() => handleMouseDown(x, y)}
                        onMouseEnter={() => handleMouseEnter(x, y)}
                        style={{
                          width: `${gridPixelSize}px`,
                          height: `${gridPixelSize}px`,
                          backgroundColor: pixel ? paintedColor : '#0a0a15',
                          border: '1px solid #222244',
                          transition: 'background-color 0.05s',
                        }}
                      />
                    ))}
                  </Box>
                ))}
              </Box>
            </Box>

            <Box textAlign="center">
              <Button.Confirm
                icon="scroll"
                onClick={handleFinalize}
                color="gold">
                Finalize Rune ({selectedScroll.faith_cost} Faith)
              </Button.Confirm>
            </Box>
          </>
        )}

        <Box textAlign="center" fontSize={0.8} opacity={0.35} mt={2} fontStyle="italic">
          Draw the sacred patterns carefully.
          <br />
          The divine recognizes only true sigils.
        </Box>
      </Window.Content>
    </Window>
  );
};
