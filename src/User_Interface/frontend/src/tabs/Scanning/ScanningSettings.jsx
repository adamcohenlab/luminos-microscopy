import { useEffect, useState } from "react";
import {
  TextValue,
  TopSection,
  addIds,
  retrieveByName,
  valueOfOrDefault,
} from "../../components/Utils";
import { useSnackbar } from "notistack";
import { SectionHeader } from "../../components/SectionHeader";
import { GrayBox } from "../../components/GrayBox";
import { Toggle } from "../../components/Toggle";
import Menu from "../../components/Menu";
import { NumberInput } from "../../components/NumberInput";
import { GeneralSettings } from "../../components/GeneralSettingsSection";
import { Button } from "../../components/Button";
import {
  framerateToMicronsPerPoint,
  getFramerate,
  startSinglePlaneGalvoAcquisition,
  startWithWaveformsGalvoAcquisition,
  startZStackGalvoAcquisition,
  turnGalvoOn,
} from "../../matlabComms/scanningComms";
import { setProperty } from "../../matlabComms/matlabHelpers.jsx";

const useGalvoOn = () => {
  const [galvoOn, setGalvoOn] = useState(false);

  // startup galvo when galvo on is switched on
  useEffect(() => {
    if (galvoOn) {
      turnGalvoOn();
    }
  }, [galvoOn]);

  return [galvoOn, setGalvoOn];
};

export const ScanningSettings = ({ experimentName }) => {
  const acquisitionTypes = addIds([
    {
      name: "Single plane",
      params: [TextValue("frames", 1, "frames")],
    },
    {
      name: "Z-Stack",
      params: [
        TextValue("averaging factor", 1, "frames"),
        TextValue("total thickness", 1, "µm"),
        TextValue("planes", 5, "planes"),
      ],
    },
    { name: "With waveforms", params: [] },
  ]);
  const [acquisitionType, setAcquisitionType] = useState(
    acquisitionTypes[0].name
  );
  const [acqParams, setAcqParams] = useState([]);
  const [galvoOn, setGalvoOn] = useGalvoOn();

  const [framerate, setFramerate] = useState(100); // default framerate is 100 Hz

  useEffect(() => {
    const params = acquisitionTypes.find(
      (t) => t.name === acquisitionType
    ).params;
    setAcqParams(params);
  }, [acquisitionType]);

  const { enqueueSnackbar } = useSnackbar();

  const getValOfParam = (name) => {
    const param = retrieveByName(name, acqParams);
    const val = valueOfOrDefault(param);
    return Number(val);
  };

  const handleOnStartGalvo = () => {
    const startAsync = async () => {
      if (acquisitionType === "With waveforms") {
        return startWithWaveformsGalvoAcquisition({
          folder: experimentName,
        });
      } else if (acquisitionType === "Single plane") {
        return startSinglePlaneGalvoAcquisition({
          numFrames: getValOfParam("frames"),
          folder: experimentName,
        });
      } else if (acquisitionType === "Z-Stack") {
        return startZStackGalvoAcquisition({
          totalThickness: getValOfParam("total thickness"),
          numPlanes: getValOfParam("planes"),
          averagingFactor: getValOfParam("averaging factor"),
          folder: experimentName,
        });
      }
    };

    startAsync().then((success) => {
      if (!success) {
        enqueueSnackbar("Acquisition failed", {
          variant: "error",
        });
      } else {
        enqueueSnackbar("Acquisition started", {
          variant: "success",
        });
      }
    });
  };

  // get framerate on startup
  useEffect(() => {
    getFramerate().then((framerate) =>
      setFrameRateOrMicronsPerPoint({ framerate })
    );
  }, []);

  const [isDisplayingFrameRate, setisDisplayingFrameRate] = useState(true);

  const [micronsPerPoint, setMicronsPerPoint] = useState(null);

  const setFrameRateOrMicronsPerPoint = async ({
    framerate,
    micronsPerPoint,
  }) => {
    if (framerate) {
      const fr = Number(framerate);
      setFramerate(fr);
      const mpp = await framerateToMicronsPerPoint(fr);
      setMicronsPerPoint(mpp);
    } else if (micronsPerPoint) {
      const mpp = Number(micronsPerPoint);
      setMicronsPerPoint(mpp);
      const fr = await micronsPerPointToFramerate(mpp);
      setFramerate(fr);
    }
    return;
  };

  return (
    <div>
      <StartScanningButton onClick={handleOnStartGalvo} />
      <SectionHeader>Scanning Settings</SectionHeader>
      <GrayBox className="w-96">
        <div className="grid grid-auto-cols-min grid-cols-2 gap-4 w-sm">
          <ParameterName name="Galvo on" />
          <Parameter>
            <Toggle enabled={galvoOn} setEnabled={setGalvoOn} />
          </Parameter>
          <ParameterName name="Acquisition type" />
          <Parameter>
            <Menu
              items={acquisitionTypes.map((t) => t.name)}
              selected={acquisitionType}
              setSelected={setAcquisitionType}
              type="vertical"
              classNameButton="rounded-full w-36"
            />
          </Parameter>
          <div className="mt-2">
            <Menu
              items={["Framerate", "Resolution"]}
              selected={isDisplayingFrameRate ? "Framerate" : "Resolution"}
              setSelected={(x) => {
                setisDisplayingFrameRate(x === "Framerate");
                setProperty(
                  "Scanning_Device",
                  "fixed_rep_rate_flag",
                  x === "Framerate"
                );
              }}
              type="vertical"
              classNameButton="bg-gray-800/0 hover:bg-gray-700/50 -ml-2"
            />
          </div>
          <Parameter>
            <div className="flex flex-row justify-between items-center gap-4">
              {isDisplayingFrameRate ? (
                <NumberInput
                  value={framerate}
                  defaultVal={20}
                  setValue={(fr) =>
                    setFrameRateOrMicronsPerPoint({ framerate: fr })
                  }
                  units="Hz"
                />
              ) : (
                <NumberInput
                  value={micronsPerPoint}
                  defaultVal={1}
                  setValue={(mpp) =>
                    setFrameRateOrMicronsPerPoint({ micronsPerPoint: mpp })
                  }
                  units="µm"
                />
              )}
              <div className="text-xs text-slate-100/50 mt-3">
                {isDisplayingFrameRate ? (
                  <>
                    {micronsPerPoint ? `${micronsPerPoint?.toFixed(2)} µm` : ""}{" "}
                  </>
                ) : (
                  <>{framerate ? `${framerate?.toFixed(2)} Hz` : ""}</>
                )}
              </div>
            </div>
          </Parameter>
        </div>
        {acqParams.length > 0 && (
          <div className="mt-6 border border-1 border-slate-100/25 rounded-md p-4">
            <GeneralSettings
              properties={acqParams}
              setProperty={(idx, val) =>
                setAcqParams((oldParams) => {
                  const newParams = [...oldParams];
                  newParams[idx].value = val;
                  return newParams;
                })
              }
            />
          </div>
        )}
      </GrayBox>
    </div>
  );
};
const ParameterName = ({ name }) => (
  <div className="my-auto font-medium">{name}</div>
);
// justify to the left
const Parameter = ({ children }) => (
  <div className="my-auto flex flex-row justify-start">{children}</div>
);
const StartScanningButton = ({ onClick }) => {
  return (
    <TopSection>
      <Button onClick={onClick}>Start Scanning Acquisition</Button>
    </TopSection>
  );
};
