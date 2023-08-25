import React, { useState, useEffect, useRef } from "react";

export const TextInput = ({
  name = "",
  defaultVal,
  units,
  value,
  setValue,
  type = "horizontal", // general settings type ("vertical" or "horizontal")
  upDownControls = false,
  disabled = false,
  onBlur = () => {},
  ...props
}) => {
  const nameInOneWord = name.replace(" ", "-");
  const [inputValue, setInputValue] = useState("");

  useEffect(() => {
    setInputValue(value);
  }, [value]);

  const inputRef = useRef(null);

  return (
    <div {...props}>
      <div className={type === "vertical" ? "flex flex-row" : ""}>
        {name && (
          <label
            htmlFor={nameInOneWord}
            className={`block text-xs font-medium text-gray-100 ${
              type === "vertical" ? "mr-4 my-auto w-40" : ""
            }`}
          >
            {name}
          </label>
        )}
        <div className="relative mt-2 shadow-sm">
          <input
            type={upDownControls ? "number" : "text"}
            name={nameInOneWord}
            id={nameInOneWord}
            className={`block w-full rounded-md border-1 border-transparent hover:border-gray-600 pl-2 focus:ring-blue-500 bg-gray-700 bg-opacity-75 text-gray-200 placeholder-gray-400 text-xs ${
              units && "pr-9"
            }`}
            placeholder={defaultVal}
            value={inputValue}
            onChange={(e) => setInputValue(e.target.value)}
            onBlur={(e) => {
              setValue(e.target.value);
              onBlur(e);
            }}
            disabled={disabled}
            ref={inputRef}
            onKeyDown={(e) => {
              if (e.key === "Enter") {
                inputRef.current.blur();
              }
            }}
          />
          {units && (
            <div className="pointer-events-none absolute inset-y-0 right-0 flex items-center pr-2">
              <span className={"text-gray-200 text-xs"}>{units}</span>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};
