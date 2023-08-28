// This is a React component that provides a button to save data to a server
import { closeApp } from "../matlabComms/miscellaneousComms";
import { XCircleIcon, XMarkIcon } from "@heroicons/react/24/outline";
import { useGlobalAppVariables } from "./GlobalAppVariablesContext";
import { useState } from "react";
import Modal from "./Modal";

export default function ExitButton() {
  const [isOpen, setIsOpen] = useState(false);

  // function to open the dialog box
  const openModal = () => {
    setIsOpen(true);
  };

  const handleCloseButtonClick = () => {
    openModal();
  };

  return (
    <>
      <XButton onClick={handleCloseButtonClick} />
      <MatlabOfflineDialog isOpen={isOpen} />
    </>
  );
}

// CloseButton component that displays a button with an icon and triggers a click event
const XButton = ({ onClick }) => {
  return (
    <button onClick={onClick} title="Exit app">
      <div className="flex flex-row gap-1 items-center font-semibold text-gray-900 bg-gray-100 hover:bg-gray-200 rounded-full py-2 px-3">
        <span>Exit</span>
        <XMarkIcon className="h-4 w-4" />
      </div>
    </button>
  );
};

// MatlabOfflineDialog component that displays a dialog box with a title, a message, and a progress bar
const MatlabOfflineDialog = ({ isOpen }) => {
  const { setIsMatlabOnline } = useGlobalAppVariables();

  return (
    <Modal isOpen={isOpen} className="h-96">
      <Modal.Title
        as="h3"
        className="text-lg font-medium leading-6 text-gray-200"
      >
        Would you like to copy your data to the server?
      </Modal.Title>
      <Modal.Body>
        <div className="flex flex-row gap-4 justify-center items-center mb-2 mt-6">
          <button
            className=" font-bold py-2 px-4 rounded-full bg-blue-500/70 hover:bg-blue-600/70"
            onClick={() => {
              closeApp({ save: true });
              setIsMatlabOnline(false);
            }}
          >
            Yes
          </button>
          <button
            className="text-white font-bold py-2 px-4 rounded-full bg-gray-500/90 hover:bg-gray-600/90"
            onClick={() => {
              closeApp({ save: false });
              setIsMatlabOnline(false);
            }}
          >
            No
          </button>
        </div>
      </Modal.Body>
    </Modal>
  );
};
