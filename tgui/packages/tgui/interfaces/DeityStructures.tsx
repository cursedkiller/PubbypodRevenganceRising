import { useBackend } from '../backend';
import { Button, Section, Stack } from '../components';
import { Window } from '../layouts';

type StructureData = {
  name: string;
  path: string;
  icon: string;
  desc: string;
  cost: number;
};

type DeityData = {
  faith: number;
  max_faith: number;
  team_colour: string;
  structures: StructureData[];
};

export const DeityStructures = (props) => {
  const { act, data } = useBackend<DeityData>();
  const { faith, max_faith, structures } = data;

  return (
    <Window title="Divine Structures" width={450} height={500}>
      <Window.Content>
        <Section
          title={`Available Faith: ${faith}/${max_faith}`}
          buttons={
            <Button
              icon="times"
              color="red"
              onClick={() => act('close')}>
              Close
            </Button>
          }>
          <Stack vertical>
            {structures.map((structure) => (
              <Stack.Item key={structure.name}>
                <Button
                  fluid
                  icon={structure.icon}
                  disabled={faith < structure.cost}
                  onClick={() =>
                    act('build', { path: structure.path })
                  }
                  tooltip={structure.desc}>
                  {structure.name}
                  {' - '}
                  {structure.cost} Faith
                </Button>
              </Stack.Item>
            ))}
          </Stack>
        </Section>
      </Window.Content>
    </Window>
  );
};
