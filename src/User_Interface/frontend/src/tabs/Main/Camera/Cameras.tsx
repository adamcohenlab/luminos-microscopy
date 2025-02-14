import React, { useState, useRef } from "react";
import { SectionHeader } from "../../../components/SectionHeader";
import SingleCamera from "./SingleCamera";
import { useMatlabVariable } from "../../../matlabComms/matlabHelpers";
import { Button } from "../../../components/Button";
import { buildWaveforms, resetDAQ } from "../../../matlabComms/waveformComms";
import { useSnackbar, SnackbarKey } from "notistack";
import { GrayBox } from "../../../components/GrayBox";
import {
  startCamAcquisition,
  update_blanking,
  restartCamera,
} from "../../../matlabComms/mainComms";
import { useGlobalAppVariables } from "../../../components/GlobalAppVariablesContext";

export const Cameras = () => {
  const [cameraNames, setCameraNames] = useMatlabVariable("name", "Camera");

  const cameraNamesArray: string[] =
    Array.isArray(cameraNames) ? cameraNames : cameraNames ? [cameraNames] : [];

  const { enqueueSnackbar, closeSnackbar } = useSnackbar();
  const { experimentName, waveformControls } = useGlobalAppVariables();
  const { getGlobalPropValue } = waveformControls;

  const [blankScreen, setBlankScreen] = useState(false);
  const activeSnackbarRef = useRef<SnackbarKey | null>(null);
  const intervalRef = useRef<number | null>(null);
  const isAcquisitionCanceledRef = useRef<boolean>(false); 

  const onClickStartAcquisition = () => {
    const totalTime = getGlobalPropValue("length"); // Dynamically get totalTime
  
    isAcquisitionCanceledRef.current = false; // Reset cancellation state
  
    startCamAcquisition(experimentName).then((success) => {
      if (!success) {
        enqueueSnackbar("Acquisition failed", {
          variant: "error",
        });
      } else {
        let countdown = totalTime; // Total countdown time in seconds
        let nextSnackbarTime = Math.floor(countdown / 5) * 5; // Round to the nearest multiple of 5
  
        if (activeSnackbarRef.current) {
          closeSnackbar(activeSnackbarRef.current);
        }
  
        // Only display the initial snackbar if totalTime < 10
        if (totalTime < 10) {
          const key = enqueueSnackbar("Acquiring data...", {
            variant: "info",
            persist: false,
          });
          activeSnackbarRef.current = key;
        }
  
        intervalRef.current = window.setInterval(() => {
          if (isAcquisitionCanceledRef.current) {
            // Stop the countdown if canceled
            if (intervalRef.current !== null) clearInterval(intervalRef.current);
            return;
          }
  
          countdown -= 1; // Decrement countdown every second
  
          if (countdown <= 0) {
            // Stop the interval
            if (intervalRef.current !== null) clearInterval(intervalRef.current);
  
            // Close the last snackbar if it's still open
            if (activeSnackbarRef.current) {
              closeSnackbar(activeSnackbarRef.current);
              activeSnackbarRef.current = null;
            }
  
            // Show the success message
            if (!isAcquisitionCanceledRef.current) {
              enqueueSnackbar("Acquisition complete", {
                variant: "success",
                persist: false,
              });
            }
          } else if (countdown <= nextSnackbarTime && totalTime >= 10) {
            // Only display snackbars for rounded times (multiples of 5)
            if (activeSnackbarRef.current) {
              closeSnackbar(activeSnackbarRef.current);
            }
  
            const newKey = enqueueSnackbar(
              `Acquiring data... (${nextSnackbarTime}s remaining)`,
              {
                variant: "info",
                persist: false,
              }
            );
            activeSnackbarRef.current = newKey;
  
            nextSnackbarTime -= 5; // Move to the next multiple of 5
          }
        }, 1000); // 1-second intervals
      }
    });
  };
  
  
  const onClickCancelAcquisition = () => {
    isAcquisitionCanceledRef.current = true; 

    if (intervalRef.current) {
      clearInterval(intervalRef.current); 
    }

    if (activeSnackbarRef.current) {
      closeSnackbar(activeSnackbarRef.current); 
    }

    resetDAQ().then((success) => {
      Promise.all(
        cameraNamesArray.map((cameraName) => restartCamera(cameraName))
      ).then(() => {
        enqueueSnackbar("Acquisition canceled", {
          variant: "success",
          persist: false,
        });
      });
    });
  };

  const handleBlankScreenChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const isChecked = e.target.checked;
    setBlankScreen(isChecked);
    update_blanking(isChecked);
  };

  return (
    <div>
      <SectionHeader>Camera Controls</SectionHeader>
      <div className="flex items-center gap-2 mb-4">
        <Button onClick={onClickStartAcquisition}>Start acquisition</Button>
        <Button onClick={onClickCancelAcquisition}>Cancel acquisition</Button>
        <GrayBox className="max-w-sm p-2">
          <input
            type="checkbox"
            id="blankScreen"
            checked={blankScreen}
            onChange={handleBlankScreenChange}
          />
          <label className="ml-1 mr-1"> Blank Screen </label>
        </GrayBox>
      </div>
      <div className="max-w-lg flex flex-col gap-5">
        {Array.isArray(cameraNamesArray) &&
          cameraNamesArray.map((name: string) => (
            <SingleCamera key={name} cameraName={name} />
          ))}
      </div>
    </div>
  );
};
