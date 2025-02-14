import React, { useState, useEffect } from "react";
import { CustomGrayBox } from "../../components/CustomGrayBox";
import { MinusCircleIcon } from "@heroicons/react/20/solid";
import { useStageStatus } from "../main/StageController";
import { getStagePosition } from "../../matlabComms/mainComms";
import ImageSlider from "./ImageSlider";
import ScanSettings from "./ScanSettings";
import { useZStageStatus, useDMDList } from "./UseDeviceStatus";
import { retrieveAO, retrieveDO, getWaveformStartupInfo } from "../../matlabComms/waveformComms";

const ScanParameterContainer = ({
  deleteScanContainer,
  id,
  getScanParameter,
}) => {
  const [scanParameter, setScanParameter] = useState("Stage position");
  const [scanType, setScanType] = useState("Linear scan");
  const [stageStartValue, setStageStartValue] = useState("");
  const [stageEndValue, setStageEndValue] = useState("");
  const [zStageStartValue, setZStageStartValue] = useState("");
  const [zStageEndValue, setZStageEndValue] = useState("");
  const [stageCustomValues, setStageCustomValues] = useState("");
  const [zStageCustomValues, setZStageCustomValues] = useState("");
  const [dmdCustomValues, setDmdCustomValues] = useState("");
  const [waveformOptions, setWaveformOptions] = useState([]);
  const [stageStatus] = useStageStatus();
  const isZStageAvailable = useZStageStatus();
  const dmdNames = useDMDList();
  const [autofocusRange, setAutofocusRangeState] = useState("");
  const [autofocusFrequency, setAutofocusFrequencyState] = useState("");

  useEffect(() => {
    const fetchWaveformOptions = async () => {
      try {
        const waveformStartupInfo = await getWaveformStartupInfo();
        const { analog_wfm_funcs, digital_wfm_funcs } = waveformStartupInfo;
  
        const aoWfms = await retrieveAO();
        const doWfms = await retrieveDO();
  
        const extractWaveformOptions = (wfmData, prefix, wfmFuncs) => {
          let options = [];
          const waveformArray = Array.isArray(wfmData) ? wfmData : [wfmData];
  
          const waveformCount = waveformArray.reduce((acc, wfm) => {
            const key = `${prefix} ${wfm.port}`; 
            acc[key] = (acc[key] || 0) + 1;
            return acc;
          }, {});
  
          waveformArray.forEach((wfm, index) => {
            if (wfm) {
              const key = `${prefix} ${wfm.port}`;
              const count = waveformCount[key];
  
              const displayName = count > 1 ? `${key} ${index + 1}` : key;
  
              const wfmDefinition = wfmFuncs.find((func) => {
                const wavefileBaseName = wfm.wavefile.replace(/^awfm_|^dwfm_/, ""); 
                return func.name === wavefileBaseName;
              });
              
  
              if (wfmDefinition) {
                options.push({
                  displayName,
                  name: wfmDefinition.name,
                  args: wfmDefinition.args || [],
                });
              }
            }
          });
  
          return options;
        };
  
        const aoOptions = aoWfms
          ? extractWaveformOptions(aoWfms, "AO", analog_wfm_funcs)
          : [];
        const doOptions = doWfms
          ? extractWaveformOptions(doWfms, "DO", digital_wfm_funcs)
          : [];
  
        setWaveformOptions([...aoOptions, ...doOptions]);
      } catch (error) {
        console.error("Error fetching waveform options:", error);
      }
    };
  
    fetchWaveformOptions();
  }, []);
  

  const handleUseCurrentForStageStart = async () => {
    try {
      const { x, y, z } = await getStagePosition();
      const positionArray = [x, y, z]
        .filter((coord) => coord !== undefined)
        .map((coord) => Math.round(coord));
      setStageStartValue(positionArray.join(", "));
    } catch (error) {
      console.error("Failed to get current stage position:", error);
    }
  };

  const handleUseCurrentForStageEnd = async () => {
    try {
      const { x, y, z } = await getStagePosition();
      const positionArray = [x, y, z]
        .filter((coord) => coord !== undefined)
        .map((coord) => Math.round(coord));
      setStageEndValue(positionArray.join(", "));
    } catch (error) {
      console.error("Failed to get current stage position:", error);
    }
  };

  const handleAddCurrentPositionToCustom = async () => {
    try {
      const { x, y, z } = await getStagePosition();
      const positionArray = [x, y, z]
        .filter((coord) => coord !== undefined)
        .map((coord) => Math.round(coord));
      const formattedPosition = positionArray.join(", ");

      if (scanParameter === "Stage position") {
        setStageCustomValues((prevValues) =>
          prevValues ? `${prevValues}; ${formattedPosition}` : formattedPosition
        );
      } else if (scanParameter === "z-Stage") {
        setZStageCustomValues((prevValues) =>
          prevValues ? `${prevValues}; ${formattedPosition}` : formattedPosition
        );
      }
    } catch (error) {
      console.error("Failed to get current stage position:", error);
    }
  };

  const handleSetAutofocusRange = (newRange) => {
    if (isNaN(newRange) || newRange < 0) {
      console.error(
        "Invalid autofocus range. Please input a valid positive number."
      );
      return;
    }
    setAutofocusRangeState(newRange);
  };

  const handleSetAutofocusFrequency = (newFrecuency) => {
    if (isNaN(newFrecuency) || newFrecuency < 0) {
      console.error(
        "Invalid autofocus frecuency. Please input a valid positive integer value."
      );
      return;
    }
    setAutofocusFrequencyState(newFrecuency);
  };

  getScanParameter.current[id] = () => ({
    scanParameter,
    scanType,
    startValue:
      scanParameter === "Stage position"
        ? stageStartValue
        : scanParameter === "z-Stage"
        ? zStageStartValue
        : null, 
    endValue:
      scanParameter === "Stage position"
        ? stageEndValue
        : scanParameter === "z-Stage"
        ? zStageEndValue
        : null, 
    customValues:
      scanParameter.includes("patterns")
        ? dmdCustomValues
        : scanParameter === "Stage position"
        ? stageCustomValues
        : zStageCustomValues,
    autofocusParams:
      scanType === "Autofocus"
        ? { range: autofocusRange, frequency: autofocusFrequency }
        : "",
  });
  

  return (
    <div className="flex space-x-4 items-center relative">      
    <CustomGrayBox className="p-5 rounded-md mb-4 max-w-sm flex-1">
        <ScanSettings
          scanParameter={scanParameter}
          setScanParameter={setScanParameter}
          scanType={scanType}
          setScanType={setScanType}
          stageStatus={stageStatus}
          isZStageAvailable={isZStageAvailable}
          dmdNames={dmdNames}
          waveformOptions={waveformOptions}
          stageStartValue={stageStartValue}
          setStageStartValue={setStageStartValue}
          handleUseCurrentForStageStart={handleUseCurrentForStageStart}
          stageEndValue={stageEndValue}
          setStageEndValue={setStageEndValue}
          handleUseCurrentForStageEnd={handleUseCurrentForStageEnd}
          zStageStartValue={zStageStartValue}
          setZStageStartValue={setZStageStartValue}
          zStageEndValue={zStageEndValue}
          setZStageEndValue={setZStageEndValue}
          stageCustomValues={stageCustomValues}
          setStageCustomValues={setStageCustomValues}
          zStageCustomValues={zStageCustomValues}
          setZStageCustomValues={setZStageCustomValues}
          dmdCustomValues={dmdCustomValues}
          setDmdCustomValues={setDmdCustomValues}
          handleAddCurrentPositionToCustom={handleAddCurrentPositionToCustom}
          autofocusRange={autofocusRange}
          setAutofocusRange={handleSetAutofocusRange}
          autofocusFrequency={autofocusFrequency}
          setAutofocusFrequency={handleSetAutofocusFrequency}
        />
      </CustomGrayBox>

      {dmdNames.includes(scanParameter.replace(" patterns", "")) && (
        <ImageSlider dmdName={scanParameter.replace(" patterns", "")} />
      )}

<div className="mt-5 ml-1">
    <button
      type="button"
      onClick={deleteScanContainer}
      className="flex items-center justify-center p-2 rounded-full focus:outline-none"
      aria-label="Delete scan container"
    >
      <MinusCircleIcon className="h-6 w-6 text-slate-400 hover:text-slate-500" />
    </button>
  </div>
    </div>
  );
};

export default ScanParameterContainer;
