/* This implements the discrete sections of the waveform tab (e.g. AO, AI, DO). 
* Each section contains multiple rows, implemented in WaveformRow.jsx*/
import { WaveformRow } from "./WaveformRow";
import { PlusCircleIcon } from "@heroicons/react/20/solid";
import { SectionHeader } from "../../components/SectionHeader";
import { GrayBox } from "../../components/GrayBox";
import { TextInput } from "../../components/TextInput";
import Menu from "../../components/Menu";
import { capitalize } from "../../components/Utils";

const AddWaveform = ({ ...props }) => (
  <div {...props}>
    <div className="pl-0">
      <button type="button">
        <PlusCircleIcon className="h-6 w-6 text-sky-400 hover:text-sky-500 mt-0.5 ml-3" />
      </button>
    </div>
  </div>
);

export const WaveformSection = ({
  header,
  waveforms,
  setWaveforms,
  options,
  defaultWaveform,
  cannotChange,
  ...props
}) => {
  const appendNewWaveform = () => {
    const randomWfmId = Math.floor(Math.random() * 1e12);
    setWaveforms([...waveforms, defaultWaveform(randomWfmId)]);
  };

  const deleteWaveform = (id) => {
    setWaveforms(waveforms.filter((waveform) => waveform.id !== id));
  };

  const setProperties = (id, dict) => {
    setWaveforms((prevWaveforms) =>
      prevWaveforms.map((waveform) => {
        if (waveform.id === id) {
          return { ...waveform, ...dict };
        }
        return waveform;
      })
    );
  };

  return (
    <div {...props}>
      <div className="flex flex-rows">
        <div>
          <SectionHeader>{header}</SectionHeader>
        </div>
        {!cannotChange && (
          <AddWaveform
            onClick={(e) => {
              e.preventDefault();
              appendNewWaveform();
            }}
          />
        )}
      </div>
      <div className="flex flex-col gap-y-4">
        {waveforms.map((waveform) => (
          <WaveformRow
            key={waveform.id}
            waveform={waveform}
            deleteWaveform={() => deleteWaveform(waveform.id)}
            setProperties={(dict) => setProperties(waveform.id, dict)}
            options={options}
            cannotChange={cannotChange}
          />
        ))}
      </div>
    </div>
  );
};

export const GlobalPropertiesSection = ({
  properties,
  setProperties,
  ...props
}) => {
  return (
    <div {...props}>
      <SectionHeader>Global Properties</SectionHeader>
      <GrayBox>
        <div className="flex flex-rows gap-4">
          {Object.entries(properties).map(([name, settings], idx) =>
            !settings.options ? (
              <TextInput
                key={idx}
                name={capitalize(name)}
                defaultVal={settings.defaultVal}
                units={settings.units}
                value={settings.value}
                setValue={(value) =>
                  setProperties({ [name]: { ...settings, value } })
                }
                className="w-24"
              />
            ) : (
              <Menu
                key={idx}
                items={settings.options}
                heading={capitalize(name)}
                setSelected={(value) =>
                  setProperties({ [name]: { ...settings, value } })
                }
                selected={settings.value}
              />
            )
          )}
        </div>
      </GrayBox>
    </div>
  );
};
