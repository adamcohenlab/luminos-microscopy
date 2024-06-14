import { useSnackbar } from "notistack";
import { useCallback, useEffect, useState } from "react";
import {
  retrieveByName,
  usePrevious,
  valueOfOrDefault,
} from "../../../components/Utils";
import { debounce } from "lodash";
import { getTvec, getWfm } from "../../../matlabComms/waveformComms";

const isTooBigToPlot = (waveformControls) => {
  const numSamples =
    valueOfOrDefault(retrieveByName("length", waveformControls.globalProps)) *
    valueOfOrDefault(retrieveByName("rate", waveformControls.globalProps)); 
  return numSamples ? numSamples > 1e6 : false;
};

export const useWaveformPlottingData = (waveformControls) => {
  const [wfmNames, setWfmNames] = useState([]);
  const [tvec, setTvec] = useState([]);
  const [wfm, setWfm] = useState([[]]);

  const { enqueueSnackbar } = useSnackbar();

  // make a stateful variable called autoplotting that is true if the number of samples is less than 1e6
  const [isAutoPlotting, setIsAutoPlotting] = useState(true);
  const prevIsAutoPlotting = usePrevious(isAutoPlotting);

  useEffect(() => {
    // update isAutoPlotting
    const isTooBig = isTooBigToPlot(waveformControls);
    setIsAutoPlotting(!isTooBig);

    // if we're no longer auto plotting, send a notification
    if (isTooBig && prevIsAutoPlotting)
      enqueueSnackbar(
        "Number of samples is too large to auto plot. Click 'Plot' to plot the waveforms.",
        {
          variant: "warning",
        }
      );
  }, [waveformControls.globalProps]);

  const fetchData = async ({ globalProps, analogOutputs, digitalOutputs }) => {
    if (!analogOutputs.length && !digitalOutputs.length) {
      setTvec([]);
      setWfm([[]]);
      return;
    }
    const tvecPromise = getTvec(globalProps);
    const wfmPromises = [];
    for (let i = 0; i < analogOutputs.length; i++) {
      wfmPromises.push(
        getWfm(
          globalProps,
          `awfm_${analogOutputs[i].fcn}`,
          analogOutputs[i].fcn_args.map((arg) => parseArg(arg))
        )
      );
    }
    for (let i = 0; i < digitalOutputs.length; i++) {
      wfmPromises.push(
        getWfm(
          globalProps,
          `dwfm_${digitalOutputs[i].fcn}`,
          digitalOutputs[i].fcn_args.map((arg) => parseArg(arg))
        )
      );
    }
    const [tvec, ...wfms] = await Promise.all([tvecPromise, ...wfmPromises]);

    setTvec(tvec);
    setWfm(wfms);
    setWfmNames([
      ...analogOutputs.map((wfm) => `${wfm.name || wfm.port}`),
      ...digitalOutputs.map((wfm) => `${wfm.name || wfm.port}`),
    ]);
  };

  // debounce fetchData
  const debouncedFetchData = useCallback(debounce(fetchData, 500), []);

  useEffect(() => {
    // if the number of samples (per channel) isn't too big, fetch the data
    if (!isTooBigToPlot(waveformControls)) {
      // debounce fetchData
      debouncedFetchData({
        globalProps: waveformControls.globalProps,
        analogOutputs: waveformControls.analogOutputs,
        digitalOutputs: waveformControls.digitalOutputs,
      });
    }
  }, [waveformControls]);

  return {
    tvec,
    wfm,
    wfmNames,
    isAutoPlotting,
    fetchData,
  };
};

const parseArg = (arg) => {
  const val = parseFloat(arg.value);
  const defaultVal = parseFloat(arg.defaultVal);
  if (!isNaN(val)) {
    return val;
  }
  if (!isNaN(defaultVal)) {
    return defaultVal;
  }
  // -Infinty == use default value
  return "-Infinity";
};
