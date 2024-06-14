import React from "react";
import { SectionHeader } from "../../../components/SectionHeader";
import SingleCamera from "./SingleCamera";
import { useMatlabVariable } from "../../../matlabComms/matlabHelpers";
import { Button } from "../../../components/Button";
import { buildWaveforms } from "../../../matlabComms/waveformComms";
import { useSnackbar } from "notistack";
import { startCamAcquisition } from "../../../matlabComms/mainComms";
import { useGlobalAppVariables } from "../../../components/GlobalAppVariablesContext";

export const Cameras = () => {
  const [cameraNames, setCameraNames] = useMatlabVariable("name", "Camera");

  // turn to array if not already
  const cameraNamesArray =
    !Array.isArray(cameraNames) && !!cameraNames ? [cameraNames] : cameraNames;

  const { enqueueSnackbar, closeSnackbar } = useSnackbar();
  const { experimentName } = useGlobalAppVariables();

  const onClickStartAcquisition = () => {
    buildWaveforms().then((successWfm) => {
      if (!successWfm) return;
      const key = enqueueSnackbar("Acquiring data...", {
        variant: "info",
        persist: true,
      });

      startCamAcquisition(experimentName).then((success) => {
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
    });
  };

  return (
    <div>
      <SectionHeader>Camera Controls</SectionHeader>
      <Button onClick={onClickStartAcquisition} className="mb-4">
        Start acquisition
      </Button>
      <div className="max-w-lg flex flex-col gap-4">
        {Array.isArray(cameraNamesArray) &&
          cameraNamesArray.map((name: string) => (
            <SingleCamera key={name} cameraName={name} />
          ))}
      </div>
    </div>
  );
};
