import React from "react";
import { PrettyTextInput } from "../../components/PrettyTextInput";

const ScanSettings = ({
  scanParameter,
  setScanParameter,
  scanType,
  setScanType,
  stageStatus,
  isZStageAvailable,
  dmdNames,
  waveformOptions,
  stageStartValue,
  setStageStartValue,
  handleUseCurrentForStageStart,
  stageEndValue,
  setStageEndValue,
  handleUseCurrentForStageEnd,
  zStageStartValue,
  setZStageStartValue,
  zStageEndValue,
  setZStageEndValue,
  stageCustomValues,
  setStageCustomValues,
  zStageCustomValues,
  setZStageCustomValues,
  dmdCustomValues,
  setDmdCustomValues,
  handleAddCurrentPositionToCustom,
  autofocusRange,
  setAutofocusRange,
  autofocusFrequency,
  setAutofocusFrequency,
}) => {
  const [selectedWaveformArgIndex, setSelectedWaveformArgIndex] = React.useState(0);
  const [selectedWaveformIndex, setSelectedWaveformIndex] = React.useState(null);

  const normalizeArgs = (args) => {
    return Array.isArray(args) ? args : [args];
  };

  const selectedWaveform =
    selectedWaveformIndex !== null ? waveformOptions[selectedWaveformIndex] : null;

    const handleScanParameterChange = (value) => {
      if (
        value === "Stage position" ||
        value === "z-Stage" ||
        dmdNames.some((name) => value === `${name} patterns`)
      ) {
        setScanParameter(value);
        setSelectedWaveformIndex(null);
    
        // Set scanType to Custom for DMD patterns
        if (value.includes("patterns")) {
          setScanType("Custom");
        }
      } else {
        const waveformIndex = waveformOptions.findIndex(
          (option) => option.displayName === value
        );
        setSelectedWaveformIndex(waveformIndex);
        setSelectedWaveformArgIndex(0);
    
        if (waveformIndex !== -1) {
          const waveform = waveformOptions[waveformIndex];
          const normalizedArgs = normalizeArgs(waveform.args);
    
          const newScanParameter = `${waveform.displayName} 1 1`;
          setScanParameter(newScanParameter);
    
          // Always set scanType to Custom for waveform options
          setScanType("Custom");
        }
      }
    };
    

  const handleWaveformArgChange = (argIndex) => {
    setSelectedWaveformArgIndex(argIndex);

    if (selectedWaveform) {
      const newScanParameter = `${selectedWaveform.displayName} 1 ${argIndex + 1}`;
      setScanParameter(newScanParameter);
    }
  };

  return (
    <div>
      {/* Scan parameter dropdown */}
      <label className="block text-sm font-semibold mb-1">Scan Parameter</label>
      <select
        value={
          selectedWaveformIndex !== null
            ? waveformOptions[selectedWaveformIndex]?.displayName || ""
            : scanParameter || ""
        }
        onChange={(e) => handleScanParameterChange(e.target.value)}
        className="w-full bg-black bg-opacity-0 outline-none border border-gray-600 border-opacity-0 hover:border-opacity-100 focus:ring-0 text-xs mb-2 max-w-sm"
      >
        {/* Stage position option */}
        {stageStatus?.isPresent && (
          <option value="Stage position" className="bg-gray-800">
            Stage position
          </option>
        )}

        {/* Z-stage option */}
        {isZStageAvailable && (
          <option value="z-Stage" className="bg-gray-800">
            z-Stage
          </option>
        )}

        {/* DMD patterns options */}
        {dmdNames?.map((dmdName) => (
          <option key={dmdName} value={`${dmdName} patterns`} className="bg-gray-800">
            {dmdName} patterns
          </option>
        ))}

        {/* Waveform options */}
        {waveformOptions?.map((option, index) => (
          <option key={index} value={option.displayName} className="bg-gray-800">
            {option.displayName}
          </option>
        ))}
      </select>

      {/* Additional dropdown for waveform args */}
      {selectedWaveform && normalizeArgs(selectedWaveform.args).length > 0 && (
        <div className="mb-1">
          <label className="block text-sm font-semibold mb-1">
            Waveform Parameter
          </label>
          <select
            value={selectedWaveformArgIndex}
            onChange={(e) => handleWaveformArgChange(Number(e.target.value))}
            className="w-full bg-black bg-opacity-0 outline-none border border-gray-600 border-opacity-0 hover:border-opacity-100 focus:ring-0 text-xs mb-2 max-w-sm"
          >
            {normalizeArgs(selectedWaveform.args).map((arg, index) => (
              <option key={index} value={index} className="bg-gray-800">
                {arg.name}
              </option>
            ))}
          </select>
        </div>
      )}

      {/* Display only "Custom" for DMD patterns */}
      {scanParameter?.includes("patterns") && (
        <>
          <label className="block text-sm font-semibold mb-1">Scan Type</label>
          <select
            value="Custom"
            disabled
            className="w-full bg-black bg-opacity-0 outline-none border border-gray-600 border-opacity-0 hover:border-opacity-100 focus:ring-0 text-xs mb-2 max-w-sm"
          >
            <option value="Custom" className="bg-gray-800">
              Custom
            </option>
          </select>
          <label className="block text-xs font-semibold text-gray-300 mb-1">
            Custom values
          </label>
          <PrettyTextInput
            placeholder="Enter DMD pattern numbers, e.g. 1,2,3;2,1"
            value={dmdCustomValues || ""}
            setValue={(value) => setDmdCustomValues(value)} // Explicitly pass the setter function
            className="w-full mb-2 bg-black bg-opacity-0 outline-none border border-gray-600 border-opacity-0 hover:border-opacity-100 focus:ring-0 focus:border-0 text-xs max-w-sm"
          />
        </>
      )}

      {/* Scan type dropdown */}
      {!scanParameter?.includes("patterns") && !selectedWaveform && (
        <>
          <label className="block text-sm font-semibold mb-1">Scan Type</label>
          <select
            value={scanType}
            onChange={(e) => setScanType(e.target.value)}
            className="w-full bg-black bg-opacity-0 outline-none border border-gray-600 border-opacity-0 hover:border-opacity-100 focus:ring-0 text-xs mb-2 max-w-sm"
          >
            <option value="Linear scan" className="bg-gray-800">
              Linear scan
            </option>
            <option value="Custom" className="bg-gray-800">
              Custom
            </option>
            {(scanParameter === "Stage position" || scanParameter === "z-Stage") && (
              <option value="Autofocus" className="bg-gray-800">
                Autofocus
              </option>
            )}
          </select>
        </>
      )}
      {selectedWaveform && (
        <>
          <label className="block text-sm font-semibold mb-1">Scan Type</label>
          <select
            value="Custom"
            disabled
            className="w-full bg-black bg-opacity-0 outline-none border border-gray-600 border-opacity-0 hover:border-opacity-100 focus:ring-0 text-xs mb-2 max-w-sm"
          >
            <option value="Custom" className="bg-gray-800">
              Custom
            </option>
          </select>
        </>
      )}


      {/* Autofocus fields */}
      {scanType === "Autofocus" && !scanParameter.includes("patterns") && (
        <>
          <div className="flex flex-col gap-1 mb-4">
            <label className="block text-xs font-semibold text-gray-300 mb-1">
              Search Range
            </label>
            <PrettyTextInput
              placeholder="Enter autofocus range"
              value={autofocusRange || ""}
              setValue={setAutofocusRange}
              className="flex-grow bg-black bg-opacity-0 outline-none border border-gray-600 border-opacity-0 hover:border-opacity-100 focus:ring-0 focus:border-0 text-xs"
            />
          </div>
          <div className="flex flex-col gap-1 mb-4">
            <label className="block text-xs font-semibold text-gray-300 mb-1">
              Refocus once every
            </label>
            <PrettyTextInput
              placeholder="Enter frequency"
              value={autofocusFrequency || ""}
              setValue={setAutofocusFrequency}
              className="flex-grow bg-black bg-opacity-0 outline-none border border-gray-600 border-opacity-0 hover:border-opacity-100 focus:ring-0 focus:border-0 text-xs"
            />
          </div>
        </>
      )}

      {/* Linear scan options for Stage position and z-Stage */}
      {scanType === "Linear scan" && !scanParameter.includes("patterns") && (
        <>
          <div className="flex flex-col gap-1 mb-4">
            <label className="block text-xs font-semibold text-gray-300 mb-1">
              Start Value
            </label>
            <div className="flex items-center gap-2">
              <PrettyTextInput
                placeholder="Start value"
                value={
                  scanParameter === "Stage position"
                    ? stageStartValue
                    : zStageStartValue
                }
                setValue={
                  scanParameter === "Stage position"
                    ? setStageStartValue
                    : setZStageStartValue
                }
                className="flex-grow bg-black bg-opacity-0 outline-none border border-gray-600 border-opacity-0 hover:border-opacity-100 focus:ring-0 focus:border-0 text-xs"
              />
              {scanParameter === "Stage position" && (
                <button
                  type="button"
                  onClick={handleUseCurrentForStageStart}
                  className="bg-blue-500 text-white py-1 px-3 rounded"
                >
                  Use Current
                </button>
              )}
            </div>
          </div>
          <div className="flex flex-col gap-1 mb-4">
            <label className="block text-xs font-semibold text-gray-300 mb-1">
              End Value
            </label>
            <div className="flex items-center gap-2">
              <PrettyTextInput
                placeholder="End value"
                value={
                  scanParameter === "Stage position"
                    ? stageEndValue
                    : zStageEndValue
                }
                setValue={
                  scanParameter === "Stage position"
                    ? setStageEndValue
                    : setZStageEndValue
                }
                className="flex-grow bg-black bg-opacity-0 outline-none border border-gray-600 border-opacity-0 hover:border-opacity-100 focus:ring-0 focus:border-0 text-xs"
              />
              {scanParameter === "Stage position" && (
                <button
                  type="button"
                  onClick={handleUseCurrentForStageEnd}
                  className="bg-blue-500 text-white py-1 px-3 rounded"
                >
                  Use Current
                </button>
              )}
            </div>
          </div>
        </>
      )}

      {/* Custom values input for Custom scan type */}
      {scanType === "Custom" && !scanParameter.includes("patterns") && (
        <>
          <label className="block text-xs font-semibold text-gray-300 mb-1">
            Custom values
          </label>
          <PrettyTextInput
            placeholder="Enter values, separated by commas"
            value={
              scanParameter === "Stage position"
                ? stageCustomValues
                : zStageCustomValues
            }
            setValue={
              scanParameter === "Stage position"
                ? setStageCustomValues
                : setZStageCustomValues
            }
            className="w-full mb-2 bg-black bg-opacity-0 outline-none border border-gray-600 border-opacity-0 hover:border-opacity-100 focus:ring-0 focus:border-0 text-xs max-w-sm"
          />
          {scanParameter === "Stage position" && (
            <button
              type="button"
              onClick={handleAddCurrentPositionToCustom}
              className="bg-blue-500 text-white py-1 px-3 rounded mt-2"
            >
              Add Current
            </button>
          )}
        </>
      )}
    </div>
  );
};

export default ScanSettings;
