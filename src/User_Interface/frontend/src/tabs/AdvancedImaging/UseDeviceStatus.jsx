import { useEffect, useState } from "react";
import { zStagePresent } from "../main/ZStage";
import { getDMDs } from "../../matlabComms/dmdComms";

export const useZStageStatus = () => {
  const [isZStageAvailable, setIsZStageAvailable] = useState(false);

  useEffect(() => {
    const checkZStageAvailability = async () => {
      const result = await zStagePresent();
      setIsZStageAvailable(result);
    };
    checkZStageAvailability();
  }, []);

  return isZStageAvailable;
};

export const useDMDList = () => {
  const [dmdNames, setDmdNames] = useState([]);

  useEffect(() => {
    const fetchDMDs = async () => {
      const dmdList = await getDMDs();
      setDmdNames(Array.isArray(dmdList) ? dmdList : dmdList ? [dmdList] : []);
    };
    fetchDMDs();
  }, []);

  return dmdNames;
};
