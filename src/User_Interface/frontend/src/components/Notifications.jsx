import React from "react";
import { SnackbarProvider, useSnackbar } from "notistack";
import { XMarkIcon } from "@heroicons/react/20/solid";
import { setEnqueueSnackbar } from "../matlabComms/matlabHelpers";

export const NotificationsProvider = ({ children }) => {
  return (
    <SnackbarProvider // notification provider
      maxSnack={3}
      action={(snackbarKey) => (
        <SnackbarCloseButton snackbarKey={snackbarKey} />
      )}
    >
      <NotificationsSubWrapper>{children}</NotificationsSubWrapper>
    </SnackbarProvider>
  );
};

// notifications close button
const SnackbarCloseButton = ({ snackbarKey }) => {
  const { closeSnackbar } = useSnackbar();
  return (
    <button onClick={() => closeSnackbar(snackbarKey)}>
      <XMarkIcon className="h-6 w-6 text-gray-100 " />
    </button>
  );
};

const NotificationsSubWrapper = ({ children }) => {
  // allow matlabComsm to enqueue notifications
  const { enqueueSnackbar } = useSnackbar();
  setEnqueueSnackbar(enqueueSnackbar);
  return children;
};
