import React, { useEffect, useState } from "react";
import { keepNDecimals } from "../../components/Utils";
import { SectionHeader } from "../../components/SectionHeader";
import { GrayBox } from "../../components/GrayBox";
import { TextInput } from "../../components/TextInput";
import {
  applyStagePosition,
  getStagePosition,
} from "../../matlabComms/mainComms";

const StageController = () => {
  // 3 text fields: x, y, and z positions
  const [x, setX] = useState(NaN);
  const [y, setY] = useState(NaN);
  const [z, setZ] = useState(NaN);

  const [currentX, setCurrentX] = useState(NaN);
  const [currentY, setCurrentY] = useState(NaN);
  const [currentZ, setCurrentZ] = useState(NaN);

  // run this function at launch
  useEffect(() => {
    // on launch, set x,y,z to current stage position
    getStagePosition().then((pos) => {
      setX(keepNDecimals(pos.x, 0));
      setY(keepNDecimals(pos.y, 0));
      setZ(keepNDecimals(pos.z, 0));
    });
  }, []);

  useEffect(() => {
    // set the timer if x,y,z are not null / NaN
    if (isNaN(x) && isNaN(y) && isNaN(z)) {
      return;
    }
    // update current stage position every sec
    const interval = setInterval(() => {
      getStagePosition().then((pos) => {
        setCurrentX(keepNDecimals(pos.x, 0));
        setCurrentY(keepNDecimals(pos.y, 0));
        setCurrentZ(keepNDecimals(pos.z, 0));
      });
    }, 1000);

    // stop the timer when the component unmounts
    return () => clearInterval(interval);
  }, [x, y, z]);

  return (
    <>
      {
        // check if x,y,z are not null / NaN
        (!isNaN(x) || !isNaN(y) || !isNaN(z)) && (
          <div>
            <SectionHeader>Stage Controller</SectionHeader>
            <GrayBox className="max-w-md">
              <div className="flex flex-col gap-4">
                <div className="flex flex-row gap-4">
                  <TextInput
                    name="X"
                    value={x}
                    setValue={(newX) => {
                      setX(newX);
                    }}
                    upDownControls={true}
                    units="µm"
                    onBlur={(e) => {
                      const newX = e.target.value;
                      applyStagePosition([newX, y, z]);
                    }}
                    // className="w-36"
                  />
                  <TextInput
                    name="Y"
                    value={y}
                    setValue={(newY) => {
                      setY(newY);
                    }}
                    upDownControls={true}
                    // className="w-24"
                    units="µm"
                    onBlur={(e) => {
                      const newY = e.target.value;
                      applyStagePosition([x, newY, z]);
                    }}
                  />
                  <TextInput
                    name="Z"
                    value={z}
                    setValue={(newZ) => {
                      setZ(newZ);
                    }}
                    upDownControls={true}
                    // className="w-24"
                    units="µm"
                    onBlur={(e) => {
                      const newZ = e.target.value;
                      applyStagePosition([x, y, newZ]);
                    }}
                  />
                </div>
                <div>{`Currently at (${currentX}, ${currentY}, ${currentZ}) µm`}</div>
              </div>
            </GrayBox>
          </div>
        )
      }
    </>
  );
};
export default StageController;
