import { ArrowPathIcon } from "@heroicons/react/20/solid";
import React from "react";
import { snap } from "../../../matlabComms/mainComms";
import { useGlobalAppVariables } from "../../GlobalAppVariablesContext";
import { useSnackbar } from "notistack";

export const useSnapMode = ({
  name = "snap", // change if you want to support multiple circle modes
}: {
  name?: string;
}) => {
  const { experimentName } = useGlobalAppVariables();
  const { enqueueSnackbar, closeSnackbar } = useSnackbar();

  const onClickSnap = () => {
    const key = enqueueSnackbar("Saving snap to file...", {
      variant: "info",
      persist: true,
    });
    snap({ folder: experimentName }).then((success) => {
      closeSnackbar(key);
      if (!success) return;
      enqueueSnackbar("Saved snap to file", { variant: "success" });
    });
  };

  return {
    sideComponent: (
      <button
        className="bg-gray-800 hover:bg-gray-700 py-2 px-3 rounded-md"
        onClick={onClickSnap}
      >
        <ArrowPathIcon className="h-4 w-4 text-gray-100 inline-block mr-2" />
        Get latest image
      </button>
    ),
    name,
  };
};
