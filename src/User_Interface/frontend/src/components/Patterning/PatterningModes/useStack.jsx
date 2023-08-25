import { useEffect, useState } from "react";
import { Square3Stack3DIcon, XMarkIcon } from "@heroicons/react/24/outline";
import { GrayBox } from "../../GrayBox";
import { HoverableButton } from "../../HoverableButton";

export const useStack = ({ allModes }) => {
  /*
    Maintain a stack of images.
    
    We need functions to add to the stack, remove from the stack, and switch between images in the stack.

    Each mode has a setShapes function that we will use when switching.
  */

  const [stack, setStack] = useState([allModes.map((mode) => mode.shapes)]);
  const [currentIdx, setCurrentIdx] = useState(0);
  useEffect(
    () =>
      setStack((prevStack) => {
        prevStack[currentIdx] = allModes.map((mode) => mode.shapes);
        return prevStack;
      }),
    [allModes]
  );

  const switchTo = (idx) => {
    if (idx < 0 || idx >= stack.length) return;
    setCurrentIdx(idx);
    allModes.forEach((mode, modeIdx) => mode.setShapes?.(stack[idx][modeIdx]));
  };

  const addFrame = () => {
    // insert a new frame after the current frame
    setStack((prevStack) => [
      ...prevStack.slice(0, currentIdx + 1),
      allModes.map((mode) => mode.shapes),
      ...prevStack.slice(currentIdx + 1),
    ]);
    setCurrentIdx((prevIdx) => prevIdx + 1);
    allModes.forEach((mode) => mode.clear?.());
  };

  const deleteFrame = (idx) => {
    if (stack.length <= 1) {
      deleteStack();
      return;
    }
    setStack((prevStack) => [
      ...prevStack.slice(0, idx),
      ...prevStack.slice(idx + 1),
    ]);
    if (currentIdx >= idx) switchTo(Math.max(0, currentIdx - 1));
  };

  const deleteStack = () => {
    setStack([allModes.map((mode) => mode.shapes)]);
    setCurrentIdx(0);
    allModes.forEach((mode) => mode.clear?.());
  };

  const [isStackMode, setIsStackMode] = useState(false);

  // delete stack when we switch away from stack mode
  useEffect(() => {
    if (!isStackMode) deleteStack();
  }, [isStackMode]);

  const stackMode = {
    title: "Stack",
    icon: <Square3Stack3DIcon className="h-6 w-6" />,
    handleButtonClick: () => setIsStackMode((prev) => !prev),
    isSelected: isStackMode,
  };

  const stackOptions = {
    sideComponent: (
      <GrayBox className="flex flex-col gap-2 rounded-none">
        <div className="flex mb-2">
          <HoverableButton onClick={addFrame} title="Add frame">
            <div className="flex items-center text-lg font-semibold h-4 w-4 justify-center">
              +
            </div>
          </HoverableButton>
        </div>
        <FrameList
          stack={stack}
          currentIdx={currentIdx}
          switchTo={switchTo}
          deleteFrame={deleteFrame}
        />
      </GrayBox>
    ),
  };

  if (!isStackMode) {
    return { allModes: [...allModes, stackMode], stack, isStackMode };
  } else {
    return {
      allModes: [...allModes, stackMode, stackOptions],
      stack,
      isStackMode,
    };
  }
};

const FrameList = ({ stack, currentIdx, switchTo, deleteFrame }) =>
  stack.map((_, idx) => (
    <div
      key={idx}
      className={`flex items-center hover:bg-gray-600 pl-2
      ${
        currentIdx === idx
          ? "bg-gray-500 hover:bg-gray-400"
          : "bg-gray-800 hover:bg-gray-700"
      }`}
    >
      <button
        onClick={() => switchTo(idx)}
        className="w-full text-left rounded-none py-1"
      >
        Frame {idx + 1}
      </button>
      <button
        className="ml-2 text-gray-400 hover:text-gray-200 p-1 hover:bg-gray-500 rounded-full"
        onClick={() => deleteFrame(idx)}
        title="Delete frame"
      >
        <XMarkIcon className="h-4 w-4" />
      </button>
    </div>
  ));
