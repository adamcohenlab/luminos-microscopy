import { Data_Relay } from "./modules/Data_Relay.js";
import { File_Server } from "./modules/File_Server.js";

const dataRelay = new Data_Relay(3010, 3009);
const fileServer = new File_Server(3011);
