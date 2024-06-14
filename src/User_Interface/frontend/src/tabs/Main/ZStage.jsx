import React, { useEffect, useState, useRef  } from "react";
import { keepNDecimals } from "../../components/Utils";
import { SectionHeader } from "../../components/SectionHeader";
import { GrayBox } from "../../components/GrayBox";
import { TextInput } from "../../components/TextInput";
import { getButtonConfigDown } from '../../components/getButtonConfigDown';
import { getButtonConfigUp } from '../../components/getButtonConfigUp';
import { SecondaryButton } from '../../components/SecondaryButton';
import {
  applyStagePosition,
  applyStagePositionRel,
  getStagePosition,
  checkStageFlag,
} from "../../matlabComms/mainComms";

const ZStage = () => {
  // 1 text field: z position
  const [zAbs, setZ] = useState(0);
  const [coarseStepSize, setCoarseStepSize] = useState(0.025); // Default 25 µm
  const [fineStepSize, setFineStepSize] = useState(0.001);  // Default 1 µm

  const updateIntervalRef = useRef(null);

  const [currentZ, setCurrentZ] = useState(0);

  // Function to update Z position rel
  const updateZPositionRel = (delta) => {
    const newZAbs = zAbs + delta;
  
    // Limit the stage to 0/12mm to avoid locking the stage. However, if the stage is already at <0 / >12mm, allow it to move down.
    if ((newZAbs < 12 && newZAbs > 0.0) || ((newZAbs > 12 && delta < 0) || (newZAbs < 0.0 && delta > 0))) {
      applyStagePositionRel(delta);
    } else {
      delta = 0;
    }
  };
  

  const startUpdatingZ = (deltaFine, deltaCoarse) => {
    let executionCount = 0; // Initialize execution count
    if (!updateIntervalRef.current) { // Check if an update interval isn't already running
      updateZPositionRel(deltaFine); // Update once immediately with deltaFine
  
      // Set up an interval that updates the position and counts executions
      updateIntervalRef.current = setInterval(() => {
        if (executionCount < 20) {
          updateZPositionRel(deltaFine); // Use deltaFine for the first 20 executions
        } else {
          updateZPositionRel(deltaCoarse); // Switch to deltaCoarse after 20 executions
        }
        executionCount++; // Increment the execution count
      }, 100); // Execute every 100ms
    }
  };
  

  // Stop updating Z position
  const stopUpdatingZ = () => {
    clearInterval(updateIntervalRef.current);
    updateIntervalRef.current = null;
  };

  // update current stage position
  useEffect(() => {
    // Define a function to fetch and update the stage position
    const fetchAndUpdateStagePosition = () => {
      getStagePosition().then((pos) => {
        // Update step sizes only if the retrieved values are not NaN
        if (!isNaN(pos.coarseStepSize)) {
          setCoarseStepSize(keepNDecimals(pos.coarseStepSize, 4));
        }
        if (!isNaN(pos.fineStepSize)) {
          setFineStepSize(keepNDecimals(pos.fineStepSize, 4));
        }
        // On launch and subsequently, set z to current stage position
        setZ(keepNDecimals(pos.zAbs, 4));
      });
    };

  // Run once at launch
  fetchAndUpdateStagePosition();

  // Set up an interval to run the function 10 times per second
  const intervalId = setInterval(fetchAndUpdateStagePosition, 100); // 100ms interval

  // Clean up the interval on component unmount
  return () => clearInterval(intervalId);
}, []);

  const moveUpButtonConfig = getButtonConfigUp({
    handleMouseDown: () => startUpdatingZ(fineStepSize, coarseStepSize), 
    name: "Move Up"
  });
  const moveDownButtonConfig = getButtonConfigDown({
    handleMouseDown: () => startUpdatingZ(-fineStepSize, -coarseStepSize), 
    name: "Move Down"
  });

  useEffect(() => {
    // set the timer if parameters are not null / NaN
    if (isNaN(zAbs)) {
      return;
    }
    // update current stage position every sec
    const interval = setInterval(() => {
      getStagePosition().then((pos) => {
        setCurrentZ(keepNDecimals(pos.zAbs, 4));
      });
    }, 1000);

    // stop the timer when the component unmounts
    return () => clearInterval(interval);
  }, [coarseStepSize, fineStepSize, zAbs]);


  return (
    <>
      {
        // check if parameters are not null / NaN
        (!isNaN(zAbs)) && checkStageFlag() && (
          <div>
            <SectionHeader>z-Stage Controller</SectionHeader>
            <GrayBox className="max-w-md">
              <div className="flex flex-col gap-4">
                <div className="flex flex-row gap-4">
                <TextInput
                    name="z-Position"
                    value={zAbs}
                    setValue={(newZ) => {
                      setCurrentZ(keepNDecimals(Math.max(Math.min(newZ,12), 0.0001)),4);
                      //setZ(keepNDecimals(Math.max(Math.min(newZ,12), 0.0001)),4);
                    }}
                    upDownControls={true}
                    // className="w-24"
                    units="mm"
                    onBlur={(e) => {
                      const value = Math.max(Math.min(e.target.value, 12),0.0001); // limit to 12mm to avoid locking the stage
                      applyStagePosition([coarseStepSize, fineStepSize, value]);
                    }}
                    />
                  <SecondaryButton
                    className="mb-4"
                    onMouseDown={moveUpButtonConfig.handleMouseDown}
                    onMouseUp={stopUpdatingZ}
                    onMouseLeave={stopUpdatingZ}
                  >
                    {moveUpButtonConfig.icon}
                  </SecondaryButton>
                  <SecondaryButton
                    className="mb-4"
                    onMouseDown={moveDownButtonConfig.handleMouseDown}
                    onMouseUp={stopUpdatingZ}
                    onMouseLeave={stopUpdatingZ}
                  >
                    {moveDownButtonConfig.icon}
                  </SecondaryButton>
                    
                  {/* <TextInput
                    name="Coarse Step Size"
                    value={coarseStepSize}
                    setValue={(newCoarseStepSize) => {
                      setCurrentCoarseStepSize(newCoarseStepSize);
                    }}
                    upDownControls={true}
                    units="µm"
                    onBlur={(e) => {
                      const newCoarseStepSize = e.target.value;
                      applyStagePosition([newCoarseStepSize, fineStepSize, zAbs]);
                    }}
                    // className="w-36"
                  />
                  <TextInput
                    name="Fine Step Size"
                    value={fineStepSize}
                    setValue={(newFineStepSize) => {
                      setCurrentFineStepSize(newFineStepSize);
                    }}
                    upDownControls={true}
                    // className="w-24"
                    units="µm"
                    onBlur={(e) => {
                      const newFineStepSize = e.target.value;
                      applyStagePosition([coarseStepSize, newFineStepSize, zAbs]);
                    }}
                  /> */}
                </div>
                {/* <div>{`Currently at ${currentZ} mm`}</div>*/}
              </div>
            </GrayBox>
          </div>
        )
      }
    </>
  );
};
export default ZStage;
