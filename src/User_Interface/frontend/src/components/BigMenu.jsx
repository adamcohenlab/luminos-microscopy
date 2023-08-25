import React from "react";
import { twMerge } from "tailwind-merge";

export const BigMenu = ({
  options,
  selected,
  setSelected,
  header,
  className,
  optionNames = null,
  ...props
}) => (
  <div className="relative flex flex-col">
    {header && (
      <label className="block text-gray-100 text-sm  mb-2">{header}</label>
    )}
    <select
      // no outline or border, add hover
      className={twMerge(
        `block appearance-none w-40 bg-gray-800 text-gray-100 py-3 px-4 pr-8 rounded leading-tight outline-none border-none cursor-pointer hover:bg-gray-700`,
        className
      )}
      value={selected}
      onChange={(e) => {
        setSelected(e.target.value);
      }}
    >
      {options.map((item, idx) => (
        <option key={item} value={item}>
          {optionNames ? optionNames[idx] : item}
        </option>
      ))}
    </select>
  </div>
);
