import { useEffect, useState } from "react";
import { addValue, makeArrayIfNotAlready } from "../../../components/Utils";
import { getWaveformStartupInfo } from "../../../matlabComms/waveformComms";
// get the list of possible waveforms and the default for display on Waveforms tab (Waveforms.jsx)
// Communications to Matlab in order to read info are implemented through waveformComms.jsx
export const useWaveformOptions = (waveformControls) => {
  const [analogOutputOptions, setAnalogOutputOptions] = useState({});
  const [digitalOutputOptions, setDigitalOutputOptions] = useState({});
  const [analogInputOptions, setAnalogInputOptions] = useState({});
  const [defaultAnalogInputWaveform, setDefaultAnalogInputWaveform] = useState(
    {}
  );
  const [defaultAnalogOutputWaveform, setDefaultAnalogOutputWaveform] =
    useState({});
  const [defaultDigitalOutputWaveform, setDefaultDigitalOutputWaveform] =
    useState({});
  const defaultGlobalProps = getDefaultGlobalProps();
  // fetch the data from matlab on startup
  useEffect(() => {
    // make async function to fetch the data from matlab
    const fetchInfo = async () => {
      const info = await getWaveformStartupInfo();
      waveformControls.setGlobalProps(
        defaultGlobalProps.map((prop) => {
          if (prop.name === "clock") {
            return {
              ...prop,
              value: info.clock_options[0],
              options: info.clock_options,
            };
          } else if (prop.name === "trigger") {
            return {
              ...prop,
              value: info.trigger_options[0],
              options: info.trigger_options,
            };
          } else if (prop.name === "completion_trigger") {
            return {
              ...prop,
              value: "None",
              options: ["None", ...info.do_ports],
            };
          } else {
            return prop;
          }
        })
      );
      setDefaultAnalogInputWaveform({
        name: "",
        port: info.ai_ports[0],
      });
      setDefaultAnalogOutputWaveform({
        name: "",
        port: info.ao_ports[0],
        fcn: info.analog_wfm_funcs[0].name,
        fcn_args: addValue(
          makeArrayIfNotAlready(info.analog_wfm_funcs[0].args)
        ),
      });
      setDefaultDigitalOutputWaveform({
        name: "",
        port: info.do_ports[0],
        fcn: info.digital_wfm_funcs[0].name,
        fcn_args: addValue(
          makeArrayIfNotAlready(info.digital_wfm_funcs[0].args)
        ),
      });
      setAnalogOutputOptions({
        ports: info.ao_ports,
        fcns: info.analog_wfm_funcs
          .map((f) => ({
            ...f,
            args: makeArrayIfNotAlready(f.args),
          }))
          .sort((a, b) =>
            a.name.toLowerCase().localeCompare(b.name.toLowerCase())
          ),
      });
      setDigitalOutputOptions({
        ports: info.do_ports,
        fcns: info.digital_wfm_funcs
          .map((f) => ({
            ...f,
            args: makeArrayIfNotAlready(f.args),
          }))
          .sort((a, b) =>
            a.name.toLowerCase().localeCompare(b.name.toLowerCase())
          ),
      });
      setAnalogInputOptions({
        ports: info.ai_ports,
      });
    };
    fetchInfo();
  }, []);
  const getDefaultWaveform = (waveformType, idx) => {
    switch (waveformType) {
      case "analogOutput":
        return { ...defaultAnalogOutputWaveform, id: idx };
      case "digitalOutput":
        return { ...defaultDigitalOutputWaveform, id: idx };
      case "analogInput":
        return { ...defaultAnalogInputWaveform, id: idx };
      default:
        return {};
    }
  };
  // set default global props if they haven't been set yet
  useEffect(() => {
    // check if globalProps has been set
    if (waveformControls.globalProps.length === 0) {
      // if not, set it to default values
      waveformControls.setGlobalProps(defaultGlobalProps);
    }
  }, [waveformControls.globalProps]);
  return {
    analogOutputOptions,
    digitalOutputOptions,
    analogInputOptions,
    getDefaultWaveform,
  };
};
const getDefaultGlobalProps = () => {
  return [
    {
      name: "length",
      value: "",
      defaultVal: "3",
      units: "s",
      type: "text",
      displayName: "Duration",
    },
    {
      name: "rate",
      displayName: "Sampling rate",
      value: "",
      defaultVal: "1e5",
      units: "Hz",
      type: "text",
    },
    { name: "clock", value: "", options: [], type: "menu" },
    {
      name: "trigger",
      displayName: "Start Trigger Port (Input)",
      value: "",
      options: [],
      type: "menu",
    },
    {
      name: "DAQ trigger",
      value: "Self-Trigger",
      options: ["Self-Trigger", "External"],
      displayName: "Trigger type",
      type: "menu",
    },
    {
      name: "completion_trigger",
      displayName: "Completion Trigger Port (Output)",
      value: "",
      options: [],
      type: "menu",
    },
  ];
};
