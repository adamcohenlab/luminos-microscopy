import express from "express";
import path from "path";
import { fileURLToPath } from "url";

// serve static files in ../../ folder from the root
export class File_Server {
  constructor(port) {
    this.port = port;
    this.setupFileServer();
  }

  setupFileServer = () => {
    const app = express();

    const __filename = fileURLToPath(import.meta.url);
    const __dirname = path.dirname(__filename);
    const imgPath = path.join(__dirname, "../imgs");

    app.use(express.static(imgPath));
    app.listen(this.port);
  };
}
