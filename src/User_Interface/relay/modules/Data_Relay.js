/* Translate data between HTTP (JS) as passed by MatlabComms.jsx and TCP/IP (Matlab) as
handled by JS_Server.m*/

// Note: server doesn't automatically reload for files in /relay (unlike /frontend)

import net from "net";
import { Server } from "socket.io";
import * as fs from "fs";
import path from "path";

export class Data_Relay {
  constructor(matlabPort, frontendPort) {
    this.frontend = new Frontend_Relay(this, frontendPort);
    this.matlab = new Matlab_Relay_For_Big_Data(this, matlabPort);

    this.matlab.setupMatlabClient();
  }
}

class Matlab_Relay {
  constructor(top, port) {
    this.retrying = false;
    this.top = top;
    this.port = port;
    this.timeout = 1000; // 1 second
    this.matlabAlive = false;
  }

  //Set up connection to Matlab client, which is implemented in JS_Server.m
  setupMatlabClient = () => {
    this.matlabClient = new net.Socket();
    this.setupMatlabEvents();
  };

  attemptConnection = () => {
    this.matlabClient.connect(this.port, "127.0.0.1");
  };

  connectEventHandler = () => {
    // console.log("MATLAB Connected");
    this.matlabAlive = true;
    this.retrying = false;
  };

  dataEventHandler = (data) => {
    throw new Error("Method not implemented.");
  };

  errorEventHandler = (err) => {};

  closeEventHandler = () => {
    this.matlabAlive = false;

    // attempt reconnection every second
    if (!this.retrying) {
      this.retrying = true;
      // console.log("Trying to connect to MATLAB...");
    }
    setTimeout(this.attemptConnection, this.timeout);
  };

  setupMatlabEvents = () => {
    this.matlabClient.on("connect", this.connectEventHandler);
    this.matlabClient.on("data", this.dataEventHandler);
    this.matlabClient.on("error", this.errorEventHandler);
    this.matlabClient.on("close", this.closeEventHandler);
    this.attemptConnection();
  };
}

class Matlab_Relay_For_Big_Data extends Matlab_Relay {
  constructor(top, port) {
    super(top, port);
    this.arr = [];
    this.metadata = null;
    this.arrLength = 0;
    this.begunDecoding = false;
    this.leftovers = null;
  }

  dataEventHandler = (data) => {
    // data consists of a JSON metadata object followed by a Float32 array
    // metadata object should have as properties:
    //   - "event"
    //   - "arrLength" if there's big data

    // add leftovers
    if (this.leftovers) {
      data = Buffer.concat([this.leftovers, data]);
      this.leftovers = null;
    }

    let arrStart = 0;
    if (!this.begunDecoding) {
      // decode the JSON object
      const dataStr = data.toString();
      const metadataEnd = dataStr.indexOf("\n") + 1;
      if (metadataEnd === 0) {
        // metadata not found, save leftovers
        this.leftovers = data;
        return;
      }

      const metadata = JSON.parse(dataStr.slice(0, metadataEnd));
      this.metadata = metadata;
      this.arrLength = metadata.arrLength || 0;

      arrStart = metadataEnd;
      this.begunDecoding = true;
    }

    // decode the Float32 array
    let val;
    let i;
    for (
      i = arrStart;
      i <= data.length - 4 && this.arr.length < this.arrLength;
      i += 4
    ) {
      val = data.readFloatLE(i);
      this.arr.push(val);
    }

    if (i > data.length - 4) {
      // there are leftovers
      this.leftovers = data.slice(i);
    }

    if (this.arr.length === this.arrLength) {
      const event = this.metadata.event;

      // delete the event and arrLength properties from the metadata object
      delete this.metadata.event;
      delete this.metadata.arrLength;

      const toFrontend =
        this.arr.length > 0 ? [...this.arr] : this.metadata.data;
      this.top.frontend.sendToFrontend(event, toFrontend);
      this.arr = [];
      this.metadata = null;
      this.begunDecoding = false;

      // if there is more data, call this function again
      if (i < data.length) {
        this.dataEventHandler(data.slice(i));
      }
    }
  };

  sendToMatlab = (msg) => {
    if (this.matlabAlive) {
      // console.log("sending to matlab", msg);
      // encode message as json
      this.matlabClient.write(JSON.stringify(msg) + "\n");
    } else {
      console.log("Retrying to send to Matlab");
      setTimeout(() => this.sendToMatlab(msg), this.timeout);
    }
  };
}

class Frontend_Relay {
  constructor(top, port) {
    this.top = top;
    this.setupFrontendSocket(port);
    this.dataFolder = "data";
  }
  // make a socketio server to talk to frontend
  setupFrontendSocket = (port) => {
    const server = new Server(port, {
      cors: {
        origin: "*",
      },
      maxHttpBufferSize: 1e9,
    });

    const handleFrontendServerConnection = (socket) => {
      if (!this.frontendAlive) {
        // console.log("Frontend connected");
      }
      this.socket = socket;
      this.frontendAlive = true;
      this.setupFrontendEvents();
    };

    server.on("connection", handleFrontendServerConnection);
  };

  sendToFrontend = (event, msg) => {
    if (this.frontendAlive) {
      // console.log("Sending to frontend", { event, msg });
      this.socket.emit(event, msg);
    } else {
      // console.log("Retrying to send to frontend");
      setTimeout(() => this.sendToFrontend(event, msg), 1000);
    }
  };

  saveFile = (data, filename) => {
    // add .json extension if it doesn't have one
    if (!filename.endsWith(".json")) {
      filename += ".json";
    }
    // save it in the data folder
    filename = path.join(this.dataFolder, filename);

    // make data folder if it doesn't exist
    if (!fs.existsSync(this.dataFolder)) {
      fs.mkdirSync(this.dataFolder);
    }

    fs.writeFile(filename, JSON.stringify(data), (err) => {
      if (err) {
        console.log("Error saving file", err);
      } else {
        // console.log("File saved");
      }
    });
  };

  loadFile = (filename, returnEvent) => {
    // add .json extension if it doesn't have one
    if (!filename.endsWith(".json")) {
      filename += ".json";
    }
    // load it from the data folder
    filename = path.join(this.dataFolder, filename);

    fs.readFile(filename, (err, data) => {
      if (err) {
        console.log("Error loading file", err);
      } else {
        // console.log("File loaded");
        this.sendToFrontend(returnEvent, JSON.parse(data));
      }
    });
  };

    getListOfFiles = (folder, returnEvent) => {
       // console.log(folder);
        if (!fs.existsSync(folder)) {
           // console.log("Creating folder", folder);
      // create folder with its parents folders too
      fs.mkdirSync(folder, { recursive: true });
    }
    fs.readdir(folder, (err, files) => {
      if (err) {
        console.log("Error getting files in folder", err);
      } else {
       // console.log("Files in folder", files);
        // remove .json extension from filenames
        files = files.map((file) => file.replace(".json", ""));
        this.sendToFrontend(returnEvent, files);
      }
    });
  };

  setupFrontendEvents = () => {
    // listen for a disconnection
    this.socket.on("disconnect", () => {
      if (this.frontendAlive) {
        // console.log("Frontend disconnected");
      }
      this.frontendAlive = false;
    });

    // listen for data from frontend and relay to matlab
    this.socket.on("sendToMatlab", (msg) => this.top.matlab.sendToMatlab(msg));

    // add events for saving/loading data
    this.socket.on("saveToFile", (msg) => {
      this.saveFile(msg.data, msg.filename);
    });
    this.socket.on("loadFromFile", (msg) =>
      this.loadFile(msg.filename, msg.return_event)
    );
    this.socket.on("getListOfFiles", (msg) =>
      this.getListOfFiles(msg.folder, msg.return_event)
    );
  };
}
