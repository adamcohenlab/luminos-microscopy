import { useEffect, useState, Dispatch, SetStateAction } from "react";
import { io } from "socket.io-client";

type MatlabMsg = {
  type: string;
  method?: string;
  args?: any[];
  devname?: string | [];
  return_event?: string;
  devtype?: string;
  properties?: string[];
  property?: string;
  value?: any;
};

type MatlabAppMethodOptions = {
  method: string;
  args?: any[];
};

type MatlabDeviceMethodOptions = {
  method: string;
  args?: any[];
  devtype: string;
  devname?: string | [];
};

export type MatlabSpecificDeviceMethodOptions = {
  method: string;
  args?: any[];
  devname?: string | [];
};

type SnackbarFunction = (msg: string, options?: any) => void;

let enqueueSnackbar: SnackbarFunction | undefined;

export const setEnqueueSnackbar = (
  snackbarFunction: SnackbarFunction
): void => {
  enqueueSnackbar = snackbarFunction;
};

export const socket = io("http://localhost:3009");

const sendToMatlab = (msg: MatlabMsg): void => {
  socket.emit("sendToMatlab", msg);
};

const matlabFunction = (msg: MatlabMsg): Promise<any> => {
  return new Promise((resolve, reject) => {
    msg.return_event = `ev${Math.floor(Math.random() * 100000000000)}`;

    socket.on(msg.return_event, (data: any) => {
      socket.off(msg.return_event);
      if (data?.error) {
        console.error(
          `MATLAB Error: ${data.error}\n\nError occured in ${msg.type} ${
            msg.method
          } ${msg.devname ? `from ${msg.devname}` : ""}`
        );
        enqueueSnackbar?.(data.error, {
          variant: "error",
          autoHideDuration: 10000,
        });
        resolve(null);
      }
      resolve(data);
    });
    sendToMatlab(msg);
  });
};

export const matlabAppMethod = async ({
  method,
  args = [],
}: MatlabAppMethodOptions): Promise<any> => {
  const data = await matlabFunction({ method, args, type: "app_method" });
  return data;
};

export const getMatlabAppProperty = async (name: string): Promise<any> => {
  const data = await matlabAppMethod({
    method: "get",
    args: [name],
  });
  return data;
};

export const matlabDeviceMethod = async (
  options: MatlabDeviceMethodOptions
): Promise<any> => {
  const newOptions: MatlabMsg = { ...options, type: "dev_method" };
  newOptions.args = newOptions.args || [];
  const data = await matlabFunction(newOptions);
  return data;
};

export const getProperties = async (
  deviceType: string,
  properties: string[],
  deviceName?: string
): Promise<any> => {
  const info = await matlabFunction({
    type: "get_properties",
    devtype: deviceType,
    properties: properties,
    ...(deviceName && { devname: deviceName }),
  });
  return info;
};

export const getPropertiesForMultipleDevices = async (
  deviceType: string,
  properties: string[],
  deviceName?: string
): Promise<any[]> => {
  const info = await getProperties(deviceType, properties, deviceName);
  const numDevices = info.numDevices;
  delete info.numDevices;
  if (numDevices === 1) return [info];

  const keys = Object.keys(info);
  const devices: any[] = [];
  for (let i = 0; i < numDevices; i++) {
    const device: any = {};
    for (const key of keys) {
      device[key] = info[key][i];
    }
    devices.push(device);
  }

  return devices;
};

export const setProperty = async (
  deviceType: string,
  property: string,
  value: any,
  deviceName?: string
): Promise<any> => {
  const success = await matlabFunction({
    type: "set_property",
    devtype: deviceType,
    property: property,
    value: value,
    ...(deviceName && { devname: deviceName }),
  });
  return success;
};

export const useMatlabVariable = <T,>(
  variableName: string,
  deviceType: string,
  deviceName?: string
): [T | null, Dispatch<SetStateAction<T | null>>] => {
  const [variable, setVariable] = useState<T | null>(null);

  useEffect(() => {
    const loadVariable = async () => {
      const properties = await getProperties(
        deviceType,
        [variableName],
        deviceName
      );
      setVariable(properties[variableName] as T);
    };
    loadVariable();
  }, [variableName, deviceType, deviceName]);

  const updateVariable = async (value: T): Promise<any> => {
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
