import { useEffect, useState } from "react";
import { closeVR, initializeVR } from "../../../matlabComms/waveformComms";

export const useVR = (waveformControls) => {
  const [VRon, setVRon] = useState(false);

  useEffect(() => {
    if (VRon) {
      initializeVR().then((success) => {
        if (success) {
          waveformControls.setCounterInputs([
            {
              name: "Rotary Encoder",
              port: "Dev1/ctr0",
            },
          ]);
        } else {
          // something went wrong with communicating with Matlab
          // TODO: display error or something
        }
      });
    } else {
      closeVR();
      waveformControls.setCounterInputs([]);
    }
  }, [VRon]);

  return {
    VRon,
    setVRon,
  };
};
