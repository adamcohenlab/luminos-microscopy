import React, { useEffect, useRef, useState } from "react";
import { prettyName } from "../../../components/Utils";
import { twMerge } from "tailwind-merge";

const Button = ({
  children,
  onClick,
  className = "",
}: {
  children: React.ReactNode;
  onClick?: () => void;
  className?: string;
}) => {
  return (
    <button
      className={twMerge(
        "m-2 bg-gray-500/50 rounded-full py-1 px-2 hover:bg-gray-400/50",
        className
      )}
      onClick={onClick}
    >
      {children}
    </button>
  );
};
const NumberField = ({
  value,
  setValue,
  optionalButton,
  title,
  ...props
}: {
  value: number;
  setValue: (x: number) => void;
  optionalButton?: React.ReactNode;
  title: string;
}) => {
  const inputRef = useRef(null);
  const [tempValue, setTempValue] = useState(String(value) || "");

  useEffect(() => {
    setTempValue(String(value));
  }, [value]);

  return (
    <div className="flex text-gray-100 rounded-sm border border-gray-600 border-opacity-0 hover:border-opacity-100 focus-within:border-blue-600 focus-within:outline-blue-600">
      <span className="whitespace-nowrap p-1 px-2 text-gray-400">{title}</span>
      <input
        className="bg-black bg-opacity-0 outline-none min-w-0 w-full text-xs border-none p-1"
        value={tempValue || ""}
        onFocus={(e) => e.target.select()}
        onChange={(e) => setTempValue(e.target.value)}
        onBlur={(e) => setValue(Number(e.target.value))}
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
const MenuField = ({
  title,
  options,
  selected,
  setSelected,
  ...props
}: {
  title: string;
  options: string[];
  selected: string;
  setSelected: (x: string) => void;
}) => {
  useEffect(() => {
    if (selected === "" || selected === null) {
      setSelected(options[0]);
    }
  });
  return (
    <div className="pb-1">
      <div className="h-6 flex text-gray-100 rounded-sm border border-gray-600 border-opacity-0 hover:border-opacity-100 focus-within:border-blue-600 focus-within:outline-blue-600">
        <span className="whitespace-nowrap text-gray-400 pl-2 my-auto">
          {title}{" "}
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

const SubTitle = ({
  title,
  className,
  ...props
}: {
  title: string;
  className?: string;
}) => (
  <div className={twMerge("font-semibold text-gray-100 p-2 my-2", className)}>
    {prettyName(title)}
  </div>
);

const Description = ({ children }: { children: React.ReactNode }) => (
  <div className="text-gray-400 text-xs ml-2 mt-4">{children}</div>
);

const TextFieldsWrapper = ({ children, ...props }) => (
  <div className="grid grid-cols-2 gap-2 gap-y-1">{children}</div>
);

const MenuFieldsWrapper = ({ children, ...props }) => (
  <div className="flex flex-col gap-y-1">{children}</div>
);

const Wrapper = ({
  children,
  title,
  className = "",
  ...props
}: {
  children: React.ReactNode;
  title: string;
  className?: string;
}) => (
  <div className={className}>
    <div className="px-2 bg-gray-800 bg-opacity-75 rounded-md w-96 relative">
      <div className="grid grid-cols-1 divide-y divide-gray-700 pb-8">
        {children}
      </div>
      <div className="absolute bottom-0 right-0 bg-slate-600 px-2 py-1 text-gray-100 text-xs rounded-br-md">
        {prettyName(title)}
      </div>
    </div>
  </div>
);

const Section = ({
  children,
  className = "",
  ...props
}: {
  children: React.ReactNode;
  className?: string;
  props?: any;
}) => (
  <div className={twMerge("pb-4", className)} {...props}>
    {children}
  </div>
);

const Camera = {
  Description,
  Button,
  NumberField,
  MenuField,
  SubTitle,
  TextFieldsWrapper,
  MenuFieldsWrapper,
  Wrapper,
  Section,
};

export default Camera;
