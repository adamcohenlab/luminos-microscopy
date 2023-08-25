import React, { useState, useEffect } from "react";

export const ScientificInput = ({ num, setNum, ...props }) => {
  const [inputValue, setInputValue] = useState(num.toString());

  const handleInputChange = (event) => {
    const newValue = event.target.value;
    setInputValue(newValue);
    const newNum = Number.parseFloat(newValue);
    if (!Number.isNaN(newNum)) {
      setNum(newNum);
    }
  };

  useEffect(() => {
    setInputValue(num.toString());
  }, [num]);

  return (
    <input
      type="text"
      value={inputValue}
      onChange={handleInputChange}
      pattern="[+-]?\d+(?:[.,]\d+)?(?:[eE][+-]?\d+)?"
      className=" bg-gray-800  text-gray-200"
    />
  );
};
