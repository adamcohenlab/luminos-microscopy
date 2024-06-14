// miscellaneous matlab comms

import { getMatlabAppProperty, matlabAppMethod } from "./matlabHelpers";
const user = await getMatlabAppProperty("User");

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

//Return location for saving temporary images (in \luminos\src\User_Interface\relay\imgs\)
//Why not just use the Matlab snaps folder in the data directory?
export const getImageFolderPath = async () => {
  //const user = await getMatlabAppProperty("User"); //This is silly. There must be a way to get and then store the name for later
  //rather than requesting anew each time.

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
