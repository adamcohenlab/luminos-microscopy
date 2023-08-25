// helper functions for communicating with matlab

import { useEffect, useState } from "react";
import { io } from "socket.io-client";

let enqueueSnackbar;

export const setEnqueueSnackbar = (snackbarFunction) => {
  enqueueSnackbar = snackbarFunction;
};

export const socket = io.connect("http://localhost:3009");

const sendToMatlab = (msg) => {
  socket.emit("sendToMatlab", msg);
};

const matlabFunction = (msg) => {
  // send a request for the data to matlab,
  // then set up a listener for the data and return a promise of the data
  return new Promise((resolve, reject) => {
    // set return_event to be a random int string
    msg.return_event = `ev${Math.floor(Math.random() * 100000000000)}`;

    socket.on(msg.return_event, (data) => {
      // remove the listener
      socket.off(msg.return_event);
      if (data?.error) {
        console.error(
          `MATLAB Error: ${data.error}\n\nError occured in ${msg.type} ${
            msg.method
          } ${!!msg.devname ? `from ${msg.devname}` : ""}`
        );
        enqueueSnackbar(data.error, {
          variant: "error",
          autoHideDuration: 10000, // 10 sec
        });

        resolve(null);
      }
      resolve(data);
    });
    sendToMatlab(msg);
  });
};

export const matlabAppMethod = async ({ method, args = [] }) => {
  const data = await matlabFunction({ method, args, type: "app_method" });
  return data;
};

export const getMatlabAppProperty = async (name) => {
  const data = await matlabAppMethod({
    method: "get",
    args: [name],
  });
  return data;
};

export const matlabDeviceMethod = async (options) => {
  options.type = "dev_method";
  options.args = options.args || []; // make sure args exists
  const data = await matlabFunction(options);
  return data;
};

export const getProperties = async (deviceType, properties, deviceName) => {
  const info = await matlabFunction({
    type: "get_properties",
    devtype: deviceType,
    properties: properties,
    ...(deviceName && { devname: deviceName }),
  });
  return info;
};

export const getPropertiesForMultipleDevices = async (
  deviceType,
  properties,
  deviceName
) => {
  /*
    Matlab returns an object with each property as an array (each element is a device)
    Here, we convert the object to an array of objects (of length numDevices)
  */

  const info = await getProperties(deviceType, properties, deviceName);

  // postprocessing

  const numDevices = info.numDevices;
  delete info.numDevices;
  if (numDevices === 1) return [info];

  const keys = Object.keys(info);
  const devices = [];
  for (let i = 0; i < numDevices; i++) {
    const device = {};
    for (const key of keys) {
      device[key] = info[key][i];
    }
    devices.push(device);
  }

  return devices;

  // Example: we return
  // [
  //   {
  //     name: "cam1",
  //     rate: 1000,
  //     length: 10,
  //   },
  //   {
  //     name: "cam2",
  //     rate: 1000,
  //     length: 10,
  //   },
  // ]
};

export const setProperty = async (deviceType, property, value, deviceName) => {
  // optionally pass in a devicename
  const success = await matlabFunction({
    type: "set_property",
    devtype: deviceType,
    property: property,
    value: value,
    ...(deviceName && { devname: deviceName }),
  });
  return success;
};

export const useMatlabVariable = (
  variableName,
  deviceType,
  deviceName = []
) => {
  // load the variable from matlab and provide a hook to update it
  const [variable, setVariable] = useState(null);

  useEffect(() => {
    const loadVariable = async () => {
      const properties = await getProperties(
        deviceType,
        [variableName],
        deviceName
      );
      setVariable(properties[variableName]);
    };
    loadVariable();
  }, [variableName, deviceType]);

  const updateVariable = async (value) => {
    setVariable(value);
    const success = await setProperty(
      deviceType,
      variableName,
      value,
      deviceName
    );
    return success;
  };

  return [variable, updateVariable];
};
