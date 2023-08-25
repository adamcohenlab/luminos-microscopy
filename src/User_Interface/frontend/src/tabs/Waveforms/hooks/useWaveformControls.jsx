import { useState } from "react";
import { retrieveByName, valueOfOrDefault } from "../../../components/Utils";

export const useWaveformControls = () => {
  const [analogOutputs, setAnalogOutputs] = useState([]);
  const [digitalOutputs, setDigitalOutputs] = useState([]);
  const [analogInputs, setAnalogInputs] = useState([]);
  const [counterInputs, setCounterInputs] = useState([]);
  const [globalProps, setGlobalProps] = useState([]);

  const getGlobalPropValue = (propName) =>
    parseFloat(valueOfOrDefault(retrieveByName(propName, globalProps)));

  // turn the globalProps array into a dictionary
  const globalPropsDict = globalProps.reduce((acc, prop) => {
    acc[prop.name] = prop;
    return acc;
  }, {});

  return {
    analogOutputs,
    setAnalogOutputs,
    digitalOutputs,
    setDigitalOutputs,
    analogInputs,
    setAnalogInputs,
    counterInputs,
    setCounterInputs,
    globalProps,
    globalPropsDict,
    setGlobalProps,
    getGlobalPropValue,
  };
};
