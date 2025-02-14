import { ChevronDoubleDownIcon } from "@heroicons/react/24/outline";
import { useSnackbar } from "notistack";

export const useExportToMatlab = ({
  handleButtonClick = (prevIsSelected, allModes = []) => {},
  name = "export",
  allModes = [],
} = {}) => {
  const { enqueueSnackbar } = useSnackbar();

  // Enhanced button click handler with notification
  const enhancedHandleButtonClick = (prevIsSelected) => {
    enqueueSnackbar("Exported shapes to dmd.shapes.", {
      variant: "success",
      persist: false,
    });
    handleButtonClick(prevIsSelected, allModes);
  };

  return {
    handleButtonClick: enhancedHandleButtonClick,
    handleButtonClickReleased: null, // Export does not need a release action
    buttonContent: (
      <div className="flex items-center space-x-2">
        <ChevronDoubleDownIcon className="h-6 w-6 text-gray-100" />
        <span className="text-gray-100">Export to Matlab</span>
      </div>
    ),
    title: "Export shapes to Matlab",
    type: "export",
    name,
    icon: (
      <ChevronDoubleDownIcon className="h-6 w-6 text-gray-100" />
    ), 
    isSelected: false, 
    helperText: "Export all drawn shapes to Matlab for further processing.",
  };
};
