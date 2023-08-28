/*
 * Main component for the Waveforms tab.
 */

import { useEffect } from "react";
import { WaveformSection } from "./WaveformSection";
import { retrieveByName } from "../../components/Utils";
import { Toggle } from "../../components/Toggle";
import { GeneralSettingsSection } from "../../components/GeneralSettingsSection";
import { TopWfmButtons } from "./TopWfmButtons";
import { useGlobalAppVariables } from "../../components/GlobalAppVariablesContext";
import { useWaveformOptions } from "./hooks/useWaveformOptions";
import { useVR } from "./hooks/useVR";
import { WaveformPlots } from "./WaveformPlots";
import { updateWaveforms } from "../../matlabComms/waveformComms";

export default function Waveforms() {
  const { waveformControls } = useGlobalAppVariables();
  const {
    analogOutputOptions,
    digitalOutputOptions,
    analogInputOptions,
    getDefaultWaveform,
  } = useWaveformOptions(waveformControls);

  const { VRon, setVRon } = useVR(waveformControls);

  // change displayName of "trigger"
  useEffect(() => {
    const newGlobalProps = [...waveformControls.globalProps];
    const triggerProp = retrieveByName("trigger", newGlobalProps);
    const daqTriggerProp = retrieveByName("DAQ trigger", newGlobalProps);

    if (daqTriggerProp?.value === "Self-Trigger") {
      // set the display name of "trigger" to "Trigger port"
      triggerProp.displayName = "Write on trigger to";
    } else if (daqTriggerProp?.value === "External") {
      // set the display name of "trigger" to "Trigger port"
      triggerProp.displayName = "Trigger port";
    }
    waveformControls.setGlobalProps(newGlobalProps);
  }, [retrieveByName("DAQ trigger", waveformControls.globalProps)?.value]);

  // send waveforms to matlab when there's a change
  useEffect(() => {
    updateWaveforms(waveformControls);
  }, [waveformControls]);

  return (
    <>
      <TopWfmButtons />
      <div className="flex flex-col gap-8">
        <WaveformPlots />
        <GeneralSettingsSection
          properties={waveformControls.globalProps}
          setProperty={(idx, value) => {
            waveformControls.setGlobalProps((oldProps) => {
              const newProps = [...oldProps];
              newProps[idx].value = value;
              return newProps;
            });
          }}
          title="Global Properties"
        >
          <div className="mt-5 w-32 flex justify-between">
            <div className="my-auto font-medium">VR</div>
            <Toggle enabled={VRon} setEnabled={setVRon} />
          </div>
        </GeneralSettingsSection>
        {VRon && (
          <WaveformSection
            header="VR Recording"
            waveforms={waveformControls.counterInputs}
            options={{}}
            cannotChange
          />
        )}
        <WaveformSection
          header="Analog Outputs"
          waveforms={waveformControls.analogOutputs}
          setWaveforms={waveformControls.setAnalogOutputs}
          options={analogOutputOptions}
          defaultWaveform={(idx) => getDefaultWaveform("analogOutput", idx)}
        />
        <WaveformSection
          header="Digital Outputs"
          waveforms={waveformControls.digitalOutputs}
          setWaveforms={waveformControls.setDigitalOutputs}
          options={digitalOutputOptions}
          defaultWaveform={(idx) => getDefaultWaveform("digitalOutput", idx)}
        />
        <WaveformSection
          header="Analog Inputs"
          waveforms={waveformControls.analogInputs}
          setWaveforms={waveformControls.setAnalogInputs}
          options={analogInputOptions}
          defaultWaveform={(idx) => getDefaultWaveform("analogInput", idx)}
        />
      </div>
    </>
  );
}
