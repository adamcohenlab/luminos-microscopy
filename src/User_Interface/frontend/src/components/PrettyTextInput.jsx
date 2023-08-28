import { useEffect, useRef, useState } from "react";

const roundDecimals = (value, maxDecimals) => {
  if (maxDecimals !== null) {
    const strValue = String(value);
    const parts = strValue.split(".");
    if (parts.length > 1 && parts[1].length > maxDecimals) {
      return Number(Number(value).toFixed(maxDecimals));
    }
  }
  return value;
};

export const PrettyTextInput = ({
  name,
  value: valueProp,
  setValue,
  onBlur = () => {},
  defaultValue = null,
  maxDecimals = null,
  ...props
}) => {
  const [internalValue, setInternalValue] = useState(valueProp);
  const [displayValue, setDisplayValue] = useState(String(valueProp));
  const inputRef = useRef(null);

  useEffect(() => {
    const roundedValue = roundDecimals(valueProp, maxDecimals);
    setInternalValue(roundedValue);
    setDisplayValue(String(roundedValue));
  }, [valueProp, maxDecimals]);

  const handleValueChange = (e) => {
    setDisplayValue(e.target.value);
    const newValue = Number(e.target.value);
    if (!isNaN(newValue)) {
      const roundedValue = roundDecimals(newValue, maxDecimals);
      setInternalValue(roundedValue);
    }
  };

  const handleKeyDown = (e) => {
    if (e.key === "Enter") {
      inputRef.current.blur();
    }
  };

  return (
    <div className="flex text-gray-100 rounded-sm border border-gray-600 border-opacity-0 hover:border-opacity-100 focus-within:border-blue-600 focus-within:outline-blue-600">
      <span className="whitespace-nowrap p-1 px-2 text-gray-400">{name}</span>
      <input
        className="bg-black bg-opacity-0 outline-none min-w-0 w-full text-xs border-none p-1"
        placeholder={defaultValue}
        value={displayValue}
        onFocus={(e) => e.target.select()}
        onChange={handleValueChange}
        onBlur={(e) => {
          const roundedValue = roundDecimals(e.target.value, maxDecimals);
          setDisplayValue(String(roundedValue));
          setValue(roundedValue);
          onBlur();
        }}
        ref={inputRef}
        onKeyDown={handleKeyDown}
        {...props}
      ></input>
    </div>
  );
};
