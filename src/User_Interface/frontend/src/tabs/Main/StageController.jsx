import React, { useEffect, useState } from "react";
import { keepNDecimals } from "../../components/Utils";
import { SectionHeader } from "../../components/SectionHeader";
import { GrayBox } from "../../components/GrayBox";
import { TextInput } from "../../components/TextInput";
import { applyStagePosition, getStagePosition } from "../../matlabComms/mainComms";

// Hook to provide stage presence status and setters
export const useStageStatus = () => {
  const [x, setX] = useState(NaN);
  const [y, setY] = useState(NaN);
  const [z, setZ] = useState(NaN);

  // Update values on mount
  useEffect(() => {
    getStagePosition().then((pos) => {
      setX(keepNDecimals(pos.x, 0));
      setY(keepNDecimals(pos.y, 0));
      setZ(keepNDecimals(pos.z, 0));
    });
  }, []);

  // Function to check stage presence status
  const stageStatus = {
    isPresent: !isNaN(x) || !isNaN(y) || !isNaN(z),
    x: !isNaN(x),
    y: !isNaN(y),
    z: !isNaN(z),
  };

  return [stageStatus, { x, y, z, setX, setY, setZ }];
};

export const StageController = () => {
  const [stageStatus, { x, y, z, setX, setY, setZ }] = useStageStatus();

  const [currentX, setCurrentX] = useState(NaN);
  const [currentY, setCurrentY] = useState(NaN);
  const [currentZ, setCurrentZ] = useState(NaN);

  // Periodically update the displayed current position values
  useEffect(() => {
    if (isNaN(x) && isNaN(y) && isNaN(z)) return;

    const interval = setInterval(() => {
      getStagePosition().then((pos) => {
        setCurrentX(keepNDecimals(pos.x, 0));
        setCurrentY(keepNDecimals(pos.y, 0));
        setCurrentZ(keepNDecimals(pos.z, 0));
      });
    }, 1000);

    return () => clearInterval(interval);
  }, [x, y, z]);

  return (
    <>
      {stageStatus.isPresent && (
        <div>
          <SectionHeader>Stage Controller</SectionHeader>
          <GrayBox className="max-w-sm">
            <div className="flex flex-col gap-4">
              <div className="flex flex-row gap-4">
                {/* Display and modify X if it is present */}
                {!isNaN(x) && (
                  <TextInput
                    name="X"
                    value={x}
                    setValue={(newX) => setX(newX)}
                    upDownControls
                    units="µm"
                    onBlur={(e) => {
                      const newX = parseFloat(e.target.value);
                      applyStagePosition([newX, y, z]);
                    }}
                  />
                )}
                {/* Display and modify Y if it is present */}
                {!isNaN(y) && (
                  <TextInput
                    name="Y"
                    value={y}
                    setValue={(newY) => setY(newY)}
                    upDownControls
                    units="µm"
                    onBlur={(e) => {
                      const newY = parseFloat(e.target.value);
                      applyStagePosition([x, newY, z]);
                    }}
                  />
                )}
                {/* Display and modify Z if it is present */}
                {!isNaN(z) && (
                  <TextInput
                    name="Z"
                    value={z}
                    setValue={(newZ) => setZ(newZ)}
                    upDownControls
                    units="µm"
                    onBlur={(e) => {
                      const newZ = parseFloat(e.target.value);
                      applyStagePosition([x, y, newZ]);
                    }}
                  />
                )}
              </div>
              <div>
                {`Currently at (${!isNaN(currentX) ? currentX + " µm" : ""}${
                  !isNaN(currentY) ? `, ${currentY} µm` : ""
                }${!isNaN(currentZ) ? `, ${currentZ} µm` : ""})`}
              </div>
            </div>
          </GrayBox>
        </div>
      )}
    </>
  );
};

export default StageController;
