classdef Placeholder < Device
    %------------------------------------------------------------------------
    % Placeholder class. Since Device is abstract, we need a
    % subclass capable of instantiation to serve as a placeholder in
    % heterogenous arrays if a certain device is unable to be loaded. This
    % class implements no functionality and is just an instantiable subclass of
    % Device.
    %-------------------------------------------------------------------------
end
