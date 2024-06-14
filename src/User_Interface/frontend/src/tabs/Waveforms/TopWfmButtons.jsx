import { runWaveforms } from "../../matlabComms/waveformComms";
import { TopSection } from "../../components/Utils";
import { Button } from "../../components/Button";
import { useSnackbar } from "notistack";
import { SecondaryButton } from "../../components/SecondaryButton";
import {
  Dialog,
  DialogActions,
  DialogContent,
  DialogContentText,
  DialogTitle,
  TextField,
  Button as MuiButton,
  Select,
  MenuItem,
} from "@mui/material";
import {
  getListOfFiles,
  loadFromFile,
  saveToFile,
} from "../../matlabComms/nodeServerComms";
import { useState } from "react";
import { useGlobalAppVariables } from "../../components/GlobalAppVariablesContext";
import { PlayIcon } from "./PlayIcon";

export const TopWfmButtons = () => {
  const { enqueueSnackbar } = useSnackbar();

  return (
    <>
      <TopSection>
        {/* align to the top right */}
        <Button
          onClick={(e) => {
            runWaveforms().then((success) => {
              if (success)
                enqueueSnackbar("Waveforms running", { variant: "success" });
              else
                enqueueSnackbar("Error running waveforms", {
                  variant: "error",
                });
            });
          }}
        >
          Run Waveforms
          <PlayIcon />
        </Button>
        <SaveWaveformsButton />
        <LoadWaveformsButton />
      </TopSection>
    </>
  );
};

const LoadWaveformsButton = () => {
  const { waveformControls } = useGlobalAppVariables();

  // select a file from a list (via getListOfFiles)
  const [open, setOpen] = useState(false);
  const [files, setFiles] = useState([]);
  const [selectedFile, setSelectedFile] = useState("");

  const loadWaveforms = async () => {
    // load the following variables from a file
    // tvec, wfm, globalProps, analogOutputs, digitalOutputs, analogInputs
    const data = await loadFromFile(selectedFile);
    console.log(selectedFile);
    waveformControls.setGlobalProps(data.globalProps);
    waveformControls.setAnalogOutputs(data.analogOutputs);
    waveformControls.setDigitalOutputs(data.digitalOutputs);
    waveformControls.setAnalogInputs(data.analogInputs);
  };

  const sortFiles = (files) =>
    files.sort(
      // sort by date
      (a, b) => {
        const { date: dateA } = parseFileName(a);
        const { date: dateB } = parseFileName(b);

        if (!dateA && !dateB) return 0; // if both dates are missing, don't sort
        if (!dateA) return 1; // if only one date is missing, sort it last
        if (!dateB) return -1;

        // turn to date objects
        const dateObjA = new Date(dateA);
        const dateObjB = new Date(dateB);

        // compare
        if (dateObjA > dateObjB) return -1;
        if (dateObjA < dateObjB) return 1;
        return 0;
      }
    );

  const fetchData = async () => {
    let files = await getListOfFiles("data"); // get files from data folder
    files = sortFiles(files);
    setFiles(files);
    setSelectedFile(files.length > 0 ? files[0] : "");
  };

  const parseFileName = (file) => {
    const pieces = file.split(" - ");
    let name, date;
    if (pieces.length <= 1) name = file;
    else {
      name = pieces.slice(0, -1).join(" - ");
      date = pieces[pieces.length - 1];
    }
    return { name, date };
  };

  return (
    <>
      <SecondaryButton
        title="Load variables"
        onClick={() => {
          fetchData();
          setOpen(true);
        }}
      >
        Load
      </SecondaryButton>
      <Dialog open={open} onClose={() => setOpen(false)}>
        <DialogTitle>Load Waveforms</DialogTitle>

        <DialogContent>
          <DialogContentText>Select a file</DialogContentText>
          <Select
            autoFocus
            margin="dense"
            id="name"
            type="text"
            fullWidth
            value={selectedFile}
            onChange={(e) => setSelectedFile(e.target.value)}
          >
            {files.map((file) => {
              // parse file name to get everything before the last " - " if it exists
              const { name, date } = parseFileName(file);
              return (
                <MenuItem key={file} value={file}>
                  <div className="flex flex-col">
                    {name}
                    {date && (
                      <span className="text-xs text-gray-400">{date}</span>
                    )}
                  </div>
                </MenuItem>
              );
            })}
          </Select>
        </DialogContent>
        <DialogActions>
          <MuiButton onClick={() => setOpen(false)} color="secondary">
            Cancel
          </MuiButton>
          <MuiButton
            onClick={() => {
              loadWaveforms();
              setOpen(false);
            }}
            color="primary"
          >
            Load
          </MuiButton>
        </DialogActions>
      </Dialog>
    </>
  );
};

const SaveWaveformsButton = () => {
  const [open, setOpen] = useState(false);
  const [name, setName] = useState("");
  const { waveformControls } = useGlobalAppVariables();
  const { globalProps, analogOutputs, digitalOutputs, analogInputs } =
    waveformControls;

  const placeholder = `file`;
  const currentDate = `${new Date().toISOString().slice(0, 10)}`;

  const saveWaveforms = () => {
    // save the following variables to a file
    // globalProps, analogOutputs, digitalOutputs, analogInputs
    const data = {
      globalProps,
      analogOutputs,
      digitalOutputs,
      analogInputs,
    };

    saveToFile(data, `${name || placeholder} - ${currentDate}`);
  };

  return (
    <>
      <SecondaryButton title="Save variables" onClick={() => setOpen(true)}>
        Save
      </SecondaryButton>
      <Dialog open={open} onClose={() => setOpen(false)}>
        <DialogTitle>Save Waveforms</DialogTitle>

        <DialogContent>
          <DialogContentText>Name</DialogContentText>
          <TextField
            autoFocus
            margin="dense"
            id="name"
            placeholder={placeholder}
            type="text"
            fullWidth
            value={name}
            onChange={(e) => setName(e.target.value)}
          />
        </DialogContent>
        <DialogActions>
          <MuiButton onClick={() => setOpen(false)} color="secondary">
            Cancel
          </MuiButton>
          <MuiButton
            onClick={() => {
              saveWaveforms();
              setOpen(false);
            }}
            color="primary"
          >
            Save
          </MuiButton>
        </DialogActions>
      </Dialog>
    </>
  );
};
