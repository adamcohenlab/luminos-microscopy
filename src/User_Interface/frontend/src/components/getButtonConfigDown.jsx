import { ArrowDownIcon } from "@heroicons/react/24/outline";

// Adjusted to accept a function that determines the action on click
export const getButtonConfigDown = ({ handleMouseDown, name = "zMoveUp" } = {}) => {
  return {
    handleMouseDown: handleMouseDown,
    icon: <ArrowDownIcon className="h-6 w-6" />,
    title: "Manual increment z",
    type: "full",
    name,
  };
};