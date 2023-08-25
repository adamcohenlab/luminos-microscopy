import React from "react";
import { Dialog, Transition } from "@headlessui/react";
import { Fragment } from "react";
import { twMerge } from "tailwind-merge";

const Modal = ({ children, isOpen, className = "" }) => (
  <Transition appear show={isOpen} as={Fragment}>
    <Dialog
      as="div"
      className={twMerge("relative z-10 text-gray-100", className)}
      onClose={() => {}}
    >
      <Transition.Child
        as={Fragment}
        enter="ease-out duration-300"
        enterFrom="opacity-0"
        enterTo="opacity-100"
        leave="ease-in duration-200"
        leaveFrom="opacity-100"
        leaveTo="opacity-0"
      >
        <div className="fixed inset-0 bg-black bg-opacity-50" />
      </Transition.Child>

      <div className="fixed inset-0 overflow-y-auto">
        <div className="flex min-h-full items-center justify-center p-4 text-center">
          <Transition.Child
            as={Fragment}
            enter="ease-out duration-300"
            enterFrom="opacity-0 scale-95"
            enterTo="opacity-100 scale-100"
            leave="ease-in duration-200"
            leaveFrom="opacity-100 scale-100"
            leaveTo="opacity-0 scale-95"
          >
            <Dialog.Panel className="w-full max-w-md transform overflow-hidden rounded-2xl bg-slate-900 p-6 text-left align-middle shadow-xl transition-all">
              {children}
            </Dialog.Panel>
          </Transition.Child>
        </div>
      </div>
    </Dialog>
  </Transition>
);

Modal.Title = ({ children, className = "" }) => (
  <Dialog.Title
    as="h3"
    className={twMerge("text-lg font-medium leading-6", className)}
  >
    {children}
  </Dialog.Title>
);

Modal.Body = ({ children, ...props }) => (
  <div className="mt-2" {...props}>
    {children}
  </div>
);

export default Modal;
