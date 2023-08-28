import React, { useState, useEffect } from "react";
import { TextInput } from "./TextInput";

export const NumberInput = ({
  value,
  setValue,
  defaultVal,
  units,
  n,
  ...props
}) => {
  // value is a number but textinput expects a string
  // defaultVal is also a number
  const [valueAsString, setValueAsString] = useState(defaultVal.toString());

  const handleInputChange = (newValue) => {
    setValueAsString(newValue);
    const newNum = Number.parseFloat(newValue);
    if (!Number.isNaN(newNum)) {
      setValue(newNum);
    }
  };

  useEffect(() => {
    setValueAsString(value.toString());
  }, [value]);

  return (
    <TextInput
      value={valueAsString}
      setValue={handleInputChange}
      defaultVal={String(defaultVal)}
      units={units}
      className="w-24"
      type="vertical"
      {...props}
    />
  );
};
