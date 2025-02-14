import React, { useEffect, useRef } from "react";

// add value prop to each object in list
export const addValue = (x) => {
  // check if x is not list
  if (x.length === undefined) {
    return { ...x, value: x };
  } else {
    return x.map((obj) => ({ ...obj, value: "" }));
  }
};

export const makeArrayIfNotAlready = (x) => {
  if (x.length === undefined) {
    return [x];
  } else {
    return x;
  }
};

export const getValueIfExists = (x) => (x ? x.value : undefined);

export const capitalize = (s) => s.charAt(0).toUpperCase() + s.slice(1);

export const prettyName = (name) => {
  // add spaces between numbers and letters
  let spaced = name.replace(/([a-z])([0-9])/gi, "$1 $2");

  // replace underlines with spaces
  spaced = spaced.replace(/_/g, " ");

  // add spaces between lowercase and uppercase letters
  spaced = spaced.replace(/([a-z])([A-Z])/g, "$1 $2");

  // capitalize first letter
  return capitalize(spaced);
};

export const getWavelength = (name) => {
  // grab wavelength from name
  let end = parseInt(name.slice(-3)); // last 3 chars
  let beginning = parseInt(name.slice(0, 3));
  if (end) return end;
  else if (beginning) return beginning;
  return null;
};

export const usePrevious = (value) => {
  const ref = useRef();
  useEffect(() => {
    ref.current = value;
  }, [value]);
  return ref.current;
};

export const addIds = (x) => x.map((obj, idx) => ({ ...obj, id: idx }));

export const retrieveById = (id, list) => list.find((obj) => obj.id === id);

export const retrieveByName = (name, list) =>
  list.find((obj) => obj.name === name);

export const setIfEmpty = (x, defaultVal) => {
  // if x is array and x = [], return defaultVal
  if (x.length === undefined) {
    return x;
  }
  if (x.length === 0) {
    return defaultVal;
  }
  return x;
};

export const linSpace = (start, stop, n) => {
  const step = (stop - start) / (n - 1);
  return Array.from({ length: n }, (_, i) => start + i * step);
};

export const keepNDecimals = (x, n) => {
  return Math.round(x * Math.pow(10, n)) / Math.pow(10, n);
};

export const TextValue = (name, defaultVal, units) => ({
  name,
  value: "",
  type: "text",
  defaultVal: defaultVal.toString(),
  units,
});

export const TopSection = ({ children }) => (
  <div className="absolute top-16 right-8 flex flex-row gap-2">{children}</div>
);

export const valueOfOrDefault = (x) =>
  x?.value === "" ? x?.defaultVal : x?.value;

export const portToChannelName = (port) => {
  // remove slashes from port
  const channelName = port ? port.replace(/\//g, "") + " " : ""; // add a space so channel is not the same as port
  return channelName;
};

// function to help with polling to matlab
// if callback returns false, stop polling (so we don't get infinite errors in matlab)
export const useInterval = (callback, delay = 250) => {
  // Save a reference to the callback function
  const savedCallback = useRef();
  // Save a reference to the interval ID
  const intervalId = useRef();

  // Update the reference to the current callback whenever it changes
  useEffect(() => {
    savedCallback.current = callback;
  }, [callback]);

  // Set up the interval and cleanup when the component is unmounted or the delay changes
  useEffect(() => {
    // Async function to call the saved callback and handle its return value
    const tick = async () => {
      // Call the saved callback if it exists and await its result
      if (savedCallback.current) {
        const keepPolling = await savedCallback.current();

        // If the result isfalse, stop the interval
        if (!keepPolling) {
          clearInterval(intervalId.current);
          return;
        }
      }
    };

    // If there is a valid delay, set up the interval and return the cleanup function
    if (delay !== null) {
      intervalId.current = setInterval(tick, delay);
      return () => clearInterval(intervalId.current);
    }
  }, [delay]);
};
