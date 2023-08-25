// This file contains the functions that communicate with the node server backend

import { socket } from "./matlabHelpers";
import { getImageFolderPath } from "./miscellaneousComms";

const nodeFunction = (msg, eventName) => {
  // execute a function in the nodejs server
  // nodejs has access to a file system (the React frontend doesn't directly),
  // so we can save/load files

  // send a request for the data to nodejs relay,
  // then set up a listener for the data and return a promise of the data
  return new Promise((resolve, reject) => {
    // set return_event to be a random int string
    msg.return_event = `ev${Math.floor(Math.random() * 100000000000)}`;

    socket.on(msg.return_event, (data) => {
      // remove the listener
      socket.off(msg.return_event);
      if (data.error) {
        console.log(data.error);
        resolve(null);
      }
      resolve(data);
    });
    socket.emit(eventName, msg);
  });
};

export const saveToFile = (data, filename) => {
  return nodeFunction({ filename, data }, "saveToFile");
};

export const loadFromFile = (filename) => {
  return nodeFunction({ filename }, "loadFromFile");
};

export const getListOfFiles = async (folder) => {
  // get saved files for waveform tab
  // folder, e.g. "imgs"

  return nodeFunction({ folder }, "getListOfFiles");
};

//Get list of images in user imgs directory. If includeDefault, then this will include images in the 'imgs/default' directory.
//Otherwise, just images in user directory.
export const getListOfImages = async (includeDefault) => {
  const folder = await getImageFolderPath();

  let files = await getListOfFiles(`imgs/${folder}`);
  files = files.map((file) => `${folder}/${file}`);

  let defaultFiles = await getListOfFiles("imgs/default");
  defaultFiles = defaultFiles.map((file) => `default/${file}`);

  let allFiles = [];
  if (includeDefault) {
    allFiles = [...defaultFiles, ...files];
  } else {
    allFiles = files;
  }
  return allFiles;
};
