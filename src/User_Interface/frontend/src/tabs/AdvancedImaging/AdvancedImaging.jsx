import React, { useState, useEffect, useRef } from "react";
import { SectionHeader } from "../../components/SectionHeader";
import { CustomGrayBox } from "../../components/CustomGrayBox";
import { PrettyTextInput } from "../../components/PrettyTextInput";
import { Generate_Hadamard, getDMDs } from "../../matlabComms/dmdComms";
import { useSnackbar } from "notistack";
import { useGlobalAppVariables } from "../../components/GlobalAppVariablesContext";
import {
  startMultipleAcquisition,
  startMultipleHadamard,
  startMultipleHiLo,
  startMultipleSnap,
  startMultipleAcquisitionScan,
  startMultipleHadamardScan,
  startMultipleHiLoScan,
  startMultipleSnapScan,
  startMultipleWaveform,
  startMultipleWaveformScan,
} from "../../matlabComms/advancedImagingComms";
import { getCameras } from "../../matlabComms/mainComms";
import { buildWaveforms } from "../../matlabComms/waveformComms";
import ScanParameterContainer from "./ScanParameterContainer";
import { PlusCircleIcon } from "@heroicons/react/20/solid";

const AdvancedImaging = () => {
  const [repetitions, setRepetitions] = useState("");
  const [experimentType, setExperimentType] = useState("Standard acquisition");
  const [hadamardSetting, setHadamardSetting] = useState([63, 14]);
  const [dmdNames, setDmdNames] = useState([]);
  const [cameraNames, setCameraNames] = useState([]);
  const [selectedHadamardDmd, setSelectedHadamardDmd] = useState(null);
  const [selectedHiLoDmd, setSelectedHiLoDmd] = useState(null);
  const [selectedHadamardCamera, setSelectedHadamardCamera] = useState(null);
  const [selectedHiLoCamera, setSelectedHiLoCamera] = useState(null);
  const [selectedSnapCamera, setSelectedSnapCamera] = useState(null);
  const { enqueueSnackbar, closeSnackbar } = useSnackbar();
  const { experimentName } = useGlobalAppVariables();
  const [scanContainers, setScanContainers] = useState([]);
  const getScanParameter = useRef({});

  useEffect(() => {
    const fetchDevices = async () => {
      const dmdList = await getDMDs();
      const cameraList = await getCameras();
      const dmdArray = Array.isArray(dmdList)
        ? dmdList
        : dmdList
        ? [dmdList]
        : [];
      const cameraArray = Array.isArray(cameraList)
        ? cameraList
        : cameraList
        ? [cameraList]
        : [];
      setDmdNames(dmdArray);
      setCameraNames(cameraArray);
      if (dmdArray.length > 0) {
        setSelectedHadamardDmd(dmdArray[0]);
        setSelectedHiLoDmd(dmdArray[0]);
      }
      if (cameraArray.length > 0) {
        setSelectedHadamardCamera(cameraArray[0]); 
        setSelectedHiLoCamera(cameraArray[0]); 
        setSelectedSnapCamera(cameraArray[0]); 
      }
    };

    fetchDevices();
  }, []);

  const handleExperimentLoop = () => {
    const scanParameters = Object.values(getScanParameter.current)
      .map((getParams) => getParams())
      .filter((params) => params.scanParameter);

    const shouldBuildWaveforms = (experimentType == "Standard acquisition" || experimentType == "Hadamard" || experimentType == "Waveform only"); // Don't build waveforms for HiLo or Snap

    const startAcquisitionProcess = () => {
      const key = enqueueSnackbar("Acquiring data...", {
        variant: "info",
        persist: true,
      });

      let startAcquisition;
      const isScan = scanParameters.length > 0;

      if (experimentType === "Standard acquisition") {
        startAcquisition = isScan
          ? startMultipleAcquisitionScan(
              experimentName,
              repetitions,
              scanParameters
            )
          : startMultipleAcquisition(experimentName, repetitions);
      } else if (experimentType === "Hadamard") {
        startAcquisition = isScan
          ? startMultipleHadamardScan(
              experimentName,
              repetitions,
              selectedHadamardDmd,
              scanParameters,
              selectedHadamardCamera
            )
          : startMultipleHadamard(
              experimentName,
              repetitions,
              selectedHadamardDmd,
              selectedHadamardCamera
            );
      } else if (experimentType === "HiLo") {
        startAcquisition = isScan
          ? startMultipleHiLoScan(
              experimentName,
              repetitions,
              selectedHiLoDmd,
              scanParameters,
              selectedHiLoCamera
            )
          : startMultipleHiLo(
              experimentName,
              repetitions,
              selectedHiLoDmd,
              selectedHiLoCamera
            );
        } else if (experimentType === "Snap") {
          startAcquisition = isScan
            ? startMultipleSnapScan(
                experimentName,
                repetitions,
                scanParameters,
                selectedSnapCamera
              )
            : startMultipleSnap(
                experimentName,
                repetitions,
                selectedSnapCamera
              );
        } else if (experimentType === "Waveform only") {
          startAcquisition = isScan
            ? startMultipleWaveformScan(
                experimentName,
                repetitions,
                scanParameters
              )
            : startMultipleWaveform(
                experimentName,
                repetitions
              );
      }

      startAcquisition.then((success) => {
        closeSnackbar(key);
        if (!success) {
          enqueueSnackbar("Acquisition failed", {
            variant: "error",
          });
        } else {
          enqueueSnackbar("Acquisition complete", {
            variant: "success",
          });
        }
      });
    };

    if (shouldBuildWaveforms) {
      buildWaveforms().then((successWfm) => {
        if (successWfm) startAcquisitionProcess();
      });
    } else {
      startAcquisitionProcess();
    }
  };

  const handleGenerateHadamard = () => {
    Generate_Hadamard(selectedHadamardDmd, hadamardSetting).then((success) => {
      enqueueSnackbar(
        success
          ? "Hadamard masks sent to DMD."
          : "Failed to generate Hadamard masks.",
        { variant: success ? "success" : "error", persist: false }
      );
    });
  };

  const addScanContainer = () => {
    const newContainer = { id: Math.random() * 1e12 };
    setScanContainers([...scanContainers, newContainer]);
  };

  const deleteScanContainer = (id) => {
    setScanContainers(
      scanContainers.filter((container) => container.id !== id)
    );
    delete getScanParameter.current[id];
  };

  return (
    <div>
      <SectionHeader />

      <div className="flex space-x-4">
        <CustomGrayBox className="p-5 rounded-md mt-4 mb-4 max-w-sm">
          <h3 className="text-lg font-semibold mb-2">Experiment selection</h3>
          <PrettyTextInput
            value={repetitions}
            setValue={setRepetitions}
            placeholder="Number of Experiments"
            className="w-full bg-black bg-opacity-0 outline-none border border-gray-600 border-opacity-0 hover:border-opacity-100 focus:ring-0 focus:border-0 text-xs"
          />
          <select
            value={experimentType}
            onChange={(e) => setExperimentType(e.target.value)}
            className="w-full bg-black bg-opacity-0 outline-none border border-gray-600 border-opacity-0 hover:border-opacity-100 focus:ring-0 text-xs max-w-sm"
          >
            <option value="Standard acquisition" className="bg-gray-800">
              Standard acquisition
            </option>
            {dmdNames.length > 0 && (
              <>
                <option value="Hadamard" className="bg-gray-800">
                  Hadamard
                </option>
                <option value="HiLo" className="bg-gray-800">
                  HiLo
                </option>
              </>
            )}
            <option value="Snap" className="bg-gray-800">
              Snap
            </option>
            <option value="Waveform only" className="bg-gray-800">
              Waveforms only
            </option>
          </select>

          <button
            onClick={handleExperimentLoop}
            className="inline-flex items-center px-3 py-1.5 border border-transparent text-xs font-medium rounded-lg shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 mt-4"
          >
            Run experiments in loop
          </button>
        </CustomGrayBox>

        {/* Show Hadamard setup dialog when selected. Allow selection of camera and DMD if multiple options are available.  */}
        {experimentType === "Hadamard" && (
          <CustomGrayBox className="p-5 rounded-md mt-4 mb-4 max-w-sm">
            <h3 className="text-lg font-semibold mb-2">
              Set up Hadamard Imaging
            </h3>
            <select
              value={JSON.stringify(hadamardSetting)}
              onChange={(e) => setHadamardSetting(JSON.parse(e.target.value))}
              className="w-full bg-black bg-opacity-0 outline-none border border-gray-600 border-opacity-0 hover:border-opacity-100 focus:ring-0 text-xs mb-4"
            >
              <option value={JSON.stringify([11, 3])} className="bg-gray-800">
                [11, 3]
              </option>
              <option value={JSON.stringify([19, 5])} className="bg-gray-800">
                [19, 5]
              </option>
              <option value={JSON.stringify([27, 6])} className="bg-gray-800">
                [27, 6]
              </option>
              <option value={JSON.stringify([35, 10])} className="bg-gray-800">
                [35, 10]
              </option>
              <option value={JSON.stringify([59, 9])} className="bg-gray-800">
                [59, 9]
              </option>
              <option value={JSON.stringify([63, 14])} className="bg-gray-800">
                [63, 14]
              </option>
            </select>

            {dmdNames.length > 1 && (
              <select
                value={selectedHadamardDmd}
                onChange={(e) => setSelectedHadamardDmd(e.target.value)}
                className="w-full bg-black bg-opacity-0 outline-none border border-gray-600 border-opacity-0 hover:border-opacity-100 focus:ring-0 text-xs mb-4"
              >
                {dmdNames.map((dmd) => (
                  <option
                    key={`hadamard-dmd-${dmd}`}
                    value={dmd}
                    className="bg-gray-800"
                  >
                    {dmd}
                  </option>
                ))}
              </select>
            )}

            {cameraNames.length > 1 && (
              <select
                value={selectedHadamardCamera}
                onChange={(e) => setSelectedHadamardCamera(e.target.value)}
                className="w-full bg-black bg-opacity-0 outline-none border border-gray-600 border-opacity-0 hover:border-opacity-100 focus:ring-0 text-xs mb-4"
              >
                {cameraNames.map((camera) => (
                  <option
                    key={`hadamard-camera-${camera}`}
                    value={camera}
                    className="bg-gray-800"
                  >
                    {camera}
                  </option>
                ))}
              </select>
            )}

            <button
              onClick={handleGenerateHadamard}
              className="bg-gray-800 hover:bg-gray-700 py-2 px-4 rounded-md text-white font-medium"
            >
              Generate Hadamard patterns
            </button>
          </CustomGrayBox>
        )}

        {/* Show HiLp setup dialog when selected. Allow selection of camera and DMD if multiple options are available.  */}
        {experimentType === "HiLo" &&
          (cameraNames.length > 1 || dmdNames.length > 1) && (
            <CustomGrayBox className="p-5 rounded-md mt-4 mb-4 max-w-sm">
              <h3 className="text-lg font-semibold mb-2">
                Set up HiLo Imaging
              </h3>
              {dmdNames.length > 1 && (
                <select
                  value={selectedHiLoDmd}
                  onChange={(e) => setSelectedHiLoDmd(e.target.value)}
                  className="w-full bg-black bg-opacity-0 outline-none border border-gray-600 border-opacity-0 hover:border-opacity-100 focus:ring-0 text-xs mb-4"
                >
                  {dmdNames.map((dmd) => (
                    <option key={dmd} value={dmd} className="bg-gray-800">
                      {dmd}
                    </option>
                  ))}
                </select>
              )}

              {cameraNames.length > 1 && (
                <select
                  value={selectedHiLoCamera}
                  onChange={(e) => setSelectedHiLoCamera(e.target.value)}
                  className="w-full bg-black bg-opacity-0 outline-none border border-gray-600 border-opacity-0 hover:border-opacity-100 focus:ring-0 text-xs mb-4"
                >
                  {cameraNames.map((camera) => (
                    <option
                      key={`hilo-camera-${camera}`}
                      value={camera}
                      className="bg-gray-800"
                    >
                      {camera}
                    </option>
                  ))}
                </select>
              )}
            </CustomGrayBox>
          )}

          {experimentType === "Snap" &&
          (cameraNames.length > 1) && (
            <CustomGrayBox className="p-5 rounded-md mt-4 mb-4 max-w-sm">
              <h3 className="text-lg font-semibold mb-2">
                Set up Multiple Snaps 
              </h3>
                <select
                  value={selectedSnapCamera}
                  onChange={(e) => setSelectedSnapCamera(e.target.value)}
                  className="w-full bg-black bg-opacity-0 outline-none border border-gray-600 border-opacity-0 hover:border-opacity-100 focus:ring-0 text-xs mb-4"
                >
                  {cameraNames.map((camera) => (
                    <option
                      key={`snap-camera-${camera}`}
                      value={camera}
                      className="bg-gray-800"
                    >
                      {camera}
                    </option>
                  ))}
                </select>
            </CustomGrayBox>
          )}
      </div>

      <div className="flex items-center space-x-2 mb-4">
        <h3 className="text-lg font-semibold mb-2">Add Scan Parameter</h3>
        <button onClick={addScanContainer}>
          <PlusCircleIcon className="h-6 w-6 mb-2 text-sky-400 hover:text-sky-500" />
        </button>
      </div>

      {scanContainers.map((container) => (
        <ScanParameterContainer
          key={container.id}
          id={container.id}
          deleteScanContainer={() => deleteScanContainer(container.id)}
          getScanParameter={getScanParameter}
        />
      ))}
    </div>
  );
};

export default AdvancedImaging;
