import React, { useEffect, useState } from "react";
import { useInterval } from "../components/Utils";
import { Toggle } from "../components/Toggle";
import { SectionHeader } from "../components/SectionHeader";
import { GrayBox } from "../components/GrayBox";
import { TextInput } from "../components/TextInput";
import {
  autoSDSpeed,
  getCameraProperties,
  getSDSpeed,
  setSDSpeed,
  toggleSD,
} from "../matlabComms/mainComms";
import { usePrevious } from "../components/Utils";

export default function SpinningDisk({ ...props }) {
  return (
    <div>
      <div className="grid grid-cols-2">
        <div className="flex flex-col gap-8">
          <SpinningDiskController />
        </div>
      </div>
    </div>
  );
}

const SpinningDiskController = ({ ...props }) => {
  //speed of spinning disk (RPM) (setpoint and current)
  const [speed, setSpeed] = useState(null);
  const [synced, setSynced] = useState(false); //Is rpm synced with camera exposure?
  const [diskOn, setDiskon] = useState(false); //Is spinning disk on?
  const [exposureTime, setExposureTime] = useState(0.15); // will update below
  const prevExposureTime = usePrevious(exposureTime);
  // run this function at launch
  useEffect(() => {
    //on launch, set speed to current speed
    getSDSpeed().then((speed) => {
      setSpeed(speed);
    });
    if (speed == 0) {
      setDiskon(false);
    } else {
      setDiskon(true);
    }
  }, []);

  // Mark as unsynced if exposure time changes
  useEffect(() => {
    if (prevExposureTime !== exposureTime) {
      setSynced(false);
    }
  }, [exposureTime]);

  // Check exposure time periodically
  useInterval(async () => {
    // Fetch camera properties
    const cameraInfo = await getCameraProperties(["exposuretime", "name"]);

    // If cameraInfo does not exist, return false to stop the interval
    if (!cameraInfo || cameraInfo.length === 0) {
      return false; // return false to stop the polling
    }
    // Update exposure time state. Convert to ms.
    setExposureTime(cameraInfo[0].exposuretime * 1000);

    // Return a non-false value if everything is successful
    return true;
  }, 100);

  // Update speed periodically (less often)
  useInterval(async () => {
    const speed = await getSDSpeed();
    if (!speed) {
      return false;
    }
    setSpeed(speed);
  }, 500);

  return (
    <div {...props}>
      <SectionHeader>Spinning Disk Controller</SectionHeader>
      <GrayBox className="max-w-md">
        <div className="mt-5 w-32 flex justify-between">
          <div className="my-auto font-medium">Disk On</div>
          <Toggle
            enabled={diskOn}
            setEnabled={(value) => {
              setDiskon(value);
              toggleSD(value);
            }}
          />
        </div>
        <div className="mt-5 mb-5 w-32 flex justify-between">
          <div className="my-auto font-medium">Synced</div>
          <Toggle
            enabled={synced}
            setEnabled={(value) => {
              if (value) {
                setSynced(value);
                autoSDSpeed(exposureTime);
              }
            }}
          />
        </div>
        <div className="flex flex-col gap-4">
          <div className="flex flex-row gap-4">
            <TextInput
              name="Speed"
              value={speed}
              setValue={(newSpeed) => {
                setSpeed(newSpeed);
              }}
              upDownControls={true}
              units="RPM"
              onBlur={(e) => {
                const newSpeed = e.target.value;
                setSDSpeed(newSpeed);
                setSynced(false);
              }}
              // className="w-36"
            />
          </div>
        </div>
      </GrayBox>
    </div>
  );
};
