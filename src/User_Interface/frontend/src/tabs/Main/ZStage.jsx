import React, { useEffect, useState, useRef } from "react";
import { keepNDecimals } from "../../components/Utils";
import { SectionHeader } from "../../components/SectionHeader";
import { GrayBox } from "../../components/GrayBox";
import { TextInput } from "../../components/TextInput";
import { getButtonConfigDown } from '../../components/getButtonConfigDown';
import { getButtonConfigUp } from '../../components/getButtonConfigUp';
import { SecondaryButton } from '../../components/SecondaryButton';
import {
  applyStagePositionZ,
  applyStagePositionRel,
  getStagePositionZ,
  checkStageFlag,
  sendHomeZ, 
} from "../../matlabComms/mainComms";
import { HomeIcon } from '@heroicons/react/20/solid';

const ZStage = () => {
  const [zAbs, setZ] = useState(0);
  const [coarseStepSize, setCoarseStepSize] = useState(0.025);
  const [fineStepSize, setFineStepSize] = useState(0.001);
  const updateIntervalRef = useRef(null);
  const [currentZ, setCurrentZ] = useState(0);

  const updateZPositionRel = (delta) => {
    const newZAbs = zAbs + delta;
    if ((newZAbs < 12 && newZAbs > 0.0) || ((newZAbs > 12 && delta < 0) || (newZAbs < 0.0 && delta > 0))) {
      applyStagePositionRel(delta);
    }
  };

  const startUpdatingZ = (deltaFine, deltaCoarse) => {
    let executionCount = 0;
    if (!updateIntervalRef.current) {
      updateZPositionRel(deltaFine);
      updateIntervalRef.current = setInterval(() => {
        if (executionCount < 20) {
          updateZPositionRel(deltaFine);
        } else {
          updateZPositionRel(deltaCoarse);
        }
        executionCount++;
      }, 100);
    }
  };

  const stopUpdatingZ = () => {
    clearInterval(updateIntervalRef.current);
    updateIntervalRef.current = null;
  };

  useEffect(() => {
    const fetchAndUpdateStagePosition = () => {
      getStagePositionZ().then((pos) => {
        // if (!isNaN(pos.coarseStepSize)) {
        //   setCoarseStepSize(keepNDecimals(pos.coarseStepSize, 4));
        // }
        // if (!isNaN(pos.fineStepSize)) {
        //   setFineStepSize(keepNDecimals(pos.fineStepSize, 4));
        // }
        setZ(keepNDecimals(pos.zAbs, 4));
      });
    };
    fetchAndUpdateStagePosition();
    const intervalId = setInterval(fetchAndUpdateStagePosition, 100);
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
    if (isNaN(zAbs)) {
      return;
    }
    const interval = setInterval(() => {
      getStagePositionZ().then((pos) => {
        setCurrentZ(keepNDecimals(pos.zAbs, 4));
      });
    }, 1000);
    return () => clearInterval(interval);
  }, [coarseStepSize, fineStepSize, zAbs]);

  return (
    <>
      {(!isNaN(zAbs)) && checkStageFlag() && (
        <div>
          <SectionHeader>z-Stage Controller</SectionHeader>
          <GrayBox className="max-w-sm">
            <div className="flex flex-col gap-4">
              <div className="flex flex-row gap-4">
                <TextInput
                  name="z-Position"
                  value={zAbs}
                  setValue={(newZ) => {
                    setCurrentZ(keepNDecimals(Math.max(Math.min(newZ,12), 0.0001)),4);
                  }}
                  upDownControls={true}
                  units="mm"
                  onBlur={(e) => {
                    const value = Math.max(Math.min(e.target.value, 12), 0.0001);
                    applyStagePositionZ([coarseStepSize, fineStepSize, value]);
                  }}
                />
                <SecondaryButton
                  className="mb-4 mt-5"
                  onMouseDown={moveUpButtonConfig.handleMouseDown}
                  onMouseUp={stopUpdatingZ}
                  onMouseLeave={stopUpdatingZ}
                >
                  {moveUpButtonConfig.icon}
                </SecondaryButton>

                <SecondaryButton
                  className="mb-4 mt-5"
                  onMouseDown={moveDownButtonConfig.handleMouseDown}
                  onMouseUp={stopUpdatingZ}
                  onMouseLeave={stopUpdatingZ}
                >
                  {moveDownButtonConfig.icon}
                </SecondaryButton>

                <SecondaryButton
                  className="mb-4 mt-5"
                  onClick={sendHomeZ} 
                >
                  <HomeIcon className="h-6 w-6" /> 
                </SecondaryButton>

              </div>
            </div>
          </GrayBox>
        </div>
      )}
    </>
  );
};

export const zStagePresent = async () => {
  const flag = await checkStageFlag();
  return flag;
};


export default ZStage;
