import { ChevronDownIcon, ChevronRightIcon } from "@heroicons/react/24/outline";
import { TextInput } from "../../components/TextInput";
import { GrayBox } from "../../components/GrayBox";
import { useMatlabVariable } from "../../matlabComms/matlabHelpers";
import { useState } from "react";
import { twMerge } from "tailwind-merge";

export const AdvancedSLMSettings = ({ className = "" }) => {
  const useSLMVariable = (variableName) =>
    useMatlabVariable(variableName, "SLM_Device");

  const [tiltX, setTiltX] = useSLMVariable("TiltX");
  const [tiltY, setTiltY] = useSLMVariable("TiltY");
  const [astX, setAstX] = useSLMVariable("AstX");
  const [astY, setAstY] = useSLMVariable("AstY");
  const [comaX, setComaX] = useSLMVariable("ComaX");
  const [comaY, setComaY] = useSLMVariable("ComaY");
  const [defocus, setDefocus] = useSLMVariable("Defocus");
  const [spherical, setSpherical] = useSLMVariable("Spherical");
  const [smoothing, setSmoothing] = useSLMVariable("smoothing");
  const [holoiterations, setHoloiterations] = useSLMVariable("holoiterations");

  const [open, setOpen] = useState(false);

  const options = [
    {
      name: "Tilt X",
      value: tiltX,
      setValue: setTiltX,
    },
    {
      name: "Tilt Y",
      value: tiltY,
      setValue: setTiltY,
    },
    {
      name: "Astigmatism X",
      value: astX,
      setValue: setAstX,
    },
    {
      name: "Astigmatism Y",
      value: astY,
      setValue: setAstY,
    },

    {
      name: "Coma X",
      value: comaX,
      setValue: setComaX,
    },
    {
      name: "Coma Y",
      value: comaY,
      setValue: setComaY,
    },
    {
      name: "Spherical",
      value: spherical,
      setValue: setSpherical,
    },
    {
      name: "Defocus",
      value: defocus,
      setValue: setDefocus,
    },
    {
      name: "Smoothing",
      value: smoothing,
      setValue: setSmoothing,
    },
    {
      name: "Hologram Iterations",
      value: holoiterations,
      setValue: setHoloiterations,
    },
  ];

  return (
    <div className={twMerge("flex flex-row", className)}>
      <div className="pr-2">
        <button type="button" onClick={() => setOpen(!open)}>
          {open ? (
            <ChevronDownIcon className="h-4 w-4" />
          ) : (
            <ChevronRightIcon className="h-4 w-4" />
          )}
        </button>
      </div>
      <div>
        <div className="text-sm font-bold">
          <button
            type="button"
            onClick={(e) => {
              e.preventDefault();
              setOpen(!open);
            }}
          >
            Advanced Settings
          </button>
        </div>
        {open && (
          <GrayBox className="mt-4">
            <div className="grid grid-cols-2 gap-4">
              {options.map(({ name, value, setValue }, idx) => (
                <TextInput
                  name={name}
                  key={idx}
                  value={value}
                  setValue={setValue}
                />
              ))}
            </div>
          </GrayBox>
        )}
      </div>
    </div>
  );
};
