import React, { useEffect, useRef } from "react";

export const Button = ({
  children,
  disabled,
  onClick,
  primary = false,
  ...props
}) => {
  const bgColor = primary ? "bg-indigo-700" : "bg-gray-600";
  const hoverColor = primary ? "hover:bg-indigo-600" : "hover:bg-gray-700";
  return (
    <div {...props}>
      <div
        className={`p-2 text-center rounded-md font-semibold text-gray-100 ${bgColor}  ${
          disabled
            ? "opacity-50 cursor-default"
            : `cursor-pointer ${hoverColor}`
        }     
        `}
        onClick={onClick}
      >
        {children}
      </div>
    </div>
  );
};
export const TextField = ({
  children,
  defaultValue,
  value,
  setValue,
  onBlur,
  optionalButton,
  ...props
}) => {
  useEffect(() => {
    if (value === "" || value === null) {
      setValue(defaultValue);
    }
  }, []);
  const inputRef = useRef(null);
  return (
    <div className="flex text-gray-100 rounded-sm border border-gray-600 border-opacity-0 hover:border-opacity-100 focus-within:border-blue-600 focus-within:outline-blue-600">
      <span className="whitespace-nowrap p-1 px-2 text-gray-400">
        {children}
      </span>
      <input
        className="bg-black bg-opacity-0 outline-none min-w-0 w-full text-xs border-none p-1"
        placeholder={defaultValue}
        value={value}
        onFocus={(e) => e.target.select()}
        onChange={(e) => setValue(e.target.value)}
        onBlur={onBlur}
        onKeyDown={(e) => {
          if (e.key === "Enter") {
            inputRef.current.blur();
          }
        }}
        ref={inputRef}
      ></input>
      {optionalButton && (
        <div className="flex items-center justify-center">{optionalButton}</div>
      )}
    </div>
  );
};
export const MenuField = ({
  children,
  options,
  selected,
  setSelected,
  ...props
}) => {
  useEffect(() => {
    if (selected === "" || selected === null) {
      setSelected(options[0]);
    }
  });
  return (
    <div {...props}>
      <div className="h-6 flex text-gray-100 rounded-sm border border-gray-600 border-opacity-0 hover:border-opacity-100 focus-within:border-blue-600 focus-within:outline-blue-600">
        <span className="whitespace-nowrap text-gray-400 pl-2 my-auto">
          {children}{" "}
        </span>

        <select
          className="bg-black bg-opacity-0 outline-none b-0 min-w-0 w-full text-xs border-0 py-0 cursor-pointer focus:ring-0 focus:border-0"
          value={selected}
          onChange={(e) => setSelected(e.target.value)}
        >
          {options.map((option, idx) => (
            <option value={option} key={idx} className="bg-gray-800">
              {option}
            </option>
          ))}
        </select>
      </div>
    </div>
  );
};
