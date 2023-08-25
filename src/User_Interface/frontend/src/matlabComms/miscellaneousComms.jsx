// miscellaneous matlab comms

import { getMatlabAppProperty, matlabAppMethod } from "./matlabHelpers";

// save the data
export const closeApp = async ({ save = false }) => {
  const success = await matlabAppMethod({
    method: "deleteJs",
    args: [save],
  });
  return success;
};

// app.jsx
export const getTabs = async () => {
  const tabs = await matlabAppMethod({
    method: "get",
    args: ["tabs"],
  });
  return tabs;
};

export const getImageFolderPath = async () => {
  const user = await getMatlabAppProperty("User");

  // Get the current date in the computer's local time zone
  const currentDate = new Date();

  // Get the computer's time zone offset in minutes
  const timeZoneOffset = currentDate.getTimezoneOffset();

  // Adjust the current date by the time zone offset
  const adjustedDate = new Date(currentDate.getTime() - timeZoneOffset * 60000); // 60k ms in a min

  // Format the adjusted date with the user's name and folder structure
  const folder = `${user.name}/${adjustedDate
    .toISOString()
    .slice(0, 10)
    .replace(/-/g, "")}`;

  return folder;
};
