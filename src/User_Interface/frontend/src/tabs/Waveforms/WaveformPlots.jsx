import { useEffect, useMemo } from "react";
import { useGlobalAppVariables } from "../../components/GlobalAppVariablesContext";
import { Plots } from "../../components/Plots";
import { useWaveformPlottingData } from "./hooks/useWaveformPlottingData";

export const WaveformPlots = ({ ...props }) => {
  const { waveformControls } = useGlobalAppVariables();
  const { tvec, wfm, wfmNames, isAutoPlotting, fetchData } =
    useWaveformPlottingData(waveformControls);

  // we use useMemo to avoid rerendering every time there is a change to the application
  const data = useMemo(() => [tvec, ...wfm], [tvec, wfm]);

  return (
    <Plots
      isAutoPlotting={isAutoPlotting}
      names={wfmNames}
      data={data}
      fetchData={() =>
        fetchData({
          globalProps: waveformControls.globalProps,
          analogOutputs: waveformControls.analogOutputs,
          digitalOutputs: waveformControls.digitalOutputs,
        })
      }
      {...props}
    />
  );
};
