import { useEffect, useMemo } from "react";
import { useGlobalAppVariables } from "../../components/GlobalAppVariablesContext";
import { Plots } from "../../components/Plots";
import { useWaveformPlottingData } from "./hooks/useWaveformPlottingData";

// Added subsampling to make the plots more responsive. There is no need to plot 10e5 points per second. DI
export const subsamplingRate = 1;

export const WaveformPlots = ({ ...props }) => {
  const { waveformControls } = useGlobalAppVariables();

  const { tvec, wfm, wfmNames, isAutoPlotting, fetchData } =
    useWaveformPlottingData(waveformControls);

  // Use useMemo to rarefy tvec and wfm by the subsamplingRate
  const subsampleData = useMemo(() => {
    // Rarefy tvec
    const subsampleTvec = tvec.filter((_, index) => index % subsamplingRate === 0);

    // Rarefy each waveform in wfm
    const subsampleWfm = wfm.map(waveform =>
      waveform.filter((_, index) => index % subsamplingRate === 0)
    );

    return [subsampleTvec, ...subsampleWfm];
  }, [tvec, wfm, subsamplingRate]);

  return (
    <Plots
      isAutoPlotting={isAutoPlotting}
      names={wfmNames}
      data={subsampleData}
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
