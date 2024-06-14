import React, { useState } from "react";
import { useEffect } from "react";
import { BigMenu } from "../BigMenu";
import { getListOfImages } from "../../matlabComms/nodeServerComms";
import { tellMatlabAboutImage } from "../../matlabComms/patterningComms";
import { snap } from "../../matlabComms/mainComms";
import { useDrawingControls } from "./DrawingControlsContext";
import { ArrowUturnLeftIcon, TrashIcon } from "@heroicons/react/24/outline";
import { imgSrc } from "./DrawROIs";
import { PatterningSettingsButton } from "./PatterningSettingsButton";

export const DrawSettings = ({
  clear,
  undo,
  deviceType,
  deviceName,
  allModes,
  children,
}) => {
  return (
    <div className="flex flex-col gap-4">
      <HorizontalButtonHolder>
        <PatterningImageSelector
          deviceType={deviceType}
          deviceName={deviceName}
        />
        <Buttons allModes={allModes} clear={clear} />
        <UndoButton undo={undo} />
        <ClearButton clear={clear} />
      </HorizontalButtonHolder>
      <HelperText allModes={allModes} />
      <div className="flex flex-row gap-2">
        <div>{children}</div>
        <VerticalButtonHolder>
          <Buttons allModes={allModes} clear={clear} side />
        </VerticalButtonHolder>
      </div>
    </div>
  );
};

const HelperText = ({ allModes }) => {
  const { mode } = useDrawingControls();

  // find the mode in allModes that matches mode
  const currentMode = allModes.find((oneMode) => oneMode.name === mode);

  return (
    <div className="text-gray-300">{currentMode?.helperText || "\u00A0"}</div>
  );
};

const VerticalButtonHolder = ({ children }) => (
  <div className="flex flex-col gap-2 w-40">{children}</div>
);

const Buttons = ({ allModes, clear, side = false }) =>
  allModes.map((mode, idx) => {
    if (side) {
      if (mode.sideComponent) return <div key={idx}>{mode.sideComponent}</div>;
    } else {
      if (mode.icon) {
        return (
          <PatterningSettingsButton
            buttonMode={mode.name}
            handleOnClick={(prevIsSelected) =>
              mode.handleButtonClick?.(prevIsSelected, clear)
            }
            title={mode.title}
            key={idx}
            disabled={mode.disabled}
            isSelected={mode.isSelected}
          >
            {mode.icon}
          </PatterningSettingsButton>
        );
      } else if (mode.component) {
        return <div key={idx}>{mode.component}</div>;
      }
    }
  });

const HorizontalButtonHolder = ({ children }) => (
  <div className="flex flex-row gap-2">{children}</div>
);

const UndoButton = ({ undo }) => (
  <PatterningSettingsButton handleOnClick={undo} title="Undo last shape">
    <ArrowUturnLeftIcon className="h-6 w-6" />
  </PatterningSettingsButton>
);
const ClearButton = ({ clear }) => (
  <PatterningSettingsButton
    handleOnClick={() => clear()}
    title="Clear all shapes"
  >
    <TrashIcon className="h-6 w-6" />
  </PatterningSettingsButton>
);

const PatterningImageSelector = ({ deviceType, deviceName = [] }) => {
  const { imgSelected, setImgSelected } = useDrawingControls();

  // get list of images from server "imgs" folder
  // let user pick one
  const setImgSelectedAndTellMatlab = (img) => {
    setImgSelected(img);
    if (
      img &&
      // img doesn't begin with "default"
      img.indexOf("default") !== 0
    )
      tellMatlabAboutImage(img, deviceType, deviceName);
  };

  const [imgs, setImgs] = useState([]);

  useEffect(() => {
    // only set imgselected if there's been a change
    if (imgSelected == "" && imgs.length > 0) {
      setImgSelectedAndTellMatlab(imgs[0]);
    }
  }, [imgs]);

  useEffect(() => {
    const getImgs = async () => {
      var imgs = await getListOfImages(false);
      //console.log("Images in snaps dir:",imgs);
      //If no images present, snap a new one and set
      // it to be the active image.
      if (imgs.length < 1) {
        snap({ folder: "temp", showDate: false });
        imgs = await getListOfImages(false);
        if (imgs.length < 1) {
          imgs = await getListOfImages(true);
        }
        setImgSelectedAndTellMatlab(imgs[0]);
      }
      //  console.log(imgs.sort().reverse());
      setImgs(imgs.sort().reverse());

      // preload images
      imgs.forEach((img) => {
        const imgObj = new Image();
        imgObj.src = imgSrc(img);
      });
    };
    // run getImgs every 0.5 seconds
    // This may be too fast, as this requires MAtlab message passing
    // to get the user every time.
    const interval = setInterval(() => {
      getImgs();
    }, 500);
    return () => clearInterval(interval);
  }, []);

  // return image menu selector
  // check if imgSelected includes 'temp.png'
  // if so, remove everything after temp.png
  let imgSelectedProcessed = imgSelected;
  if (imgSelected.includes("temp.png")) {
    imgSelectedProcessed = imgSelected.split("temp.png")[0] + "temp.png";
  }

  return (
    <BigMenu
      options={imgs}
      optionNames={imgs.map(
        (img) =>
          // remove the folders, just show the file name
          img.split("/").slice(-1)[0]
      )}
      selected={imgSelectedProcessed}
      setSelected={setImgSelectedAndTellMatlab}
    />
  );
};
