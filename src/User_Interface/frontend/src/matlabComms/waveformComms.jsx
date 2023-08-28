// This file contains the functions that communicate with the matlab backend
// for waveforms

import {
  portToChannelName,
  retrieveByName,
  valueOfOrDefault,
} from "../components/Utils";
import { setProperty } from "./matlabHelpers";
import { matlabAppMethod, matlabDeviceMethod } from "./matlabHelpers";

export const getWaveformStartupInfo = async () => {
  const startupInfo = await matlabAppMethod({
    method: "get_wfm_startup_info_js",
    args: [],
  });
  return startupInfo;
};

const daqMethod = async (x) => {
  const success = await matlabDeviceMethod({
    devtype: "DAQ",
    ...x,
  });
  return success;
};

export const getWfm = async (globalProps, wavefile, params) => {
  const wfm = await daqMethod({
    method: "Calculate_Waveform",
    args: [
      {
        rate: parseFloat(valueOfOrDefault(retrieveByName("rate", globalProps))),
        total_time: parseFloat(
          valueOfOrDefault(retrieveByName("length", globalProps))
        ),
      },
      { wavefile, params },
    ],
  });

  return wfm || [];
};

export const getTvec = async (globalProps) => {
  const tvec = await daqMethod({
    method: "Calculate_tvec",
    args: [
      {
        rate: parseFloat(valueOfOrDefault(retrieveByName("rate", globalProps))),
        total_time: parseFloat(
          valueOfOrDefault(retrieveByName("length", globalProps))
        ),
      },
    ],
  });

  return tvec;
};

// send the waveform data to matlab
export const updateWaveforms = async (waveformControls) => {
  const {
    globalPropsDict,
    analogInputs,
    analogOutputs,
    digitalOutputs,
    counterInputs,
  } = waveformControls;

  const processOutputWfmsForMatlab = (wfms, type) =>
    wfms.map((wfm) => ({
      name: wfm.name || portToChannelName(wfm.port),
      port: wfm.port,
      wavefile: `${type === "ao" ? "a" : "d"}wfm_${wfm.fcn}`,
      params: wfm.fcn_args.map((arg) => {
        const argFloat = parseFloat(arg.value);
        if (isNaN(argFloat)) {
          return parseFloat(arg.defaultVal);
        }
        return argFloat;
      }),
    }));

  const processInputWfmsForMatlab = (wfms) =>
    wfms.map((wfm) => ({
      name: wfm.name || wfm.port,
      ...wfm,
    }));

  let globalPropsToSend, wfmDataToSend;
  try {
    globalPropsToSend = {
      rate: parseFloat(valueOfOrDefault(globalPropsDict.rate)),
      total_time: parseFloat(valueOfOrDefault(globalPropsDict.length)),
      trigger_source: globalPropsDict.trigger.value,
      clock_source:
        globalPropsDict.clock.value === "Internal"
          ? " "
          : globalPropsDict.clock.value,
      daq_master:
        globalPropsDict["DAQ trigger"].value ===
        globalPropsDict["DAQ trigger"].options[0], // turn into boolean for compatibility with matlab code
    };
    wfmDataToSend = {
      ao: processOutputWfmsForMatlab(analogOutputs, "ao"),
      do: processOutputWfmsForMatlab(digitalOutputs, "do"),
      ai: processInputWfmsForMatlab(analogInputs),
      ctri: processInputWfmsForMatlab(counterInputs),
    };
  } catch (e) {
    // don't error out because it's likely that the data hasn't been loaded yet
    return false;
  }

  const success1 = await setProperty("DAQ", "global_props", globalPropsToSend);
  const success2 = await setProperty("DAQ", "wfm_data", wfmDataToSend);

  return success1 && success2;
};

export const runWaveforms = async (folder = "") => {
  const success = await matlabAppMethod({
    method: "Waveform_Standalone_Acquisition_JS",
    args: [folder],
  });
  return success;
};

export const buildWaveforms = async () => {
  const success = await daqMethod({
    method: "Build_Waveforms",
    args: [],
  });
  return success;
};

export const initializeVR = async () => {
  const success = await matlabAppMethod({
    method: "InitializeVR",
    args: [],
  });
  return success;
};

export const closeVR = async () => {
  const success = await matlabAppMethod({
    method: "CloseVR",
    args: [],
  });
  return success;
};
