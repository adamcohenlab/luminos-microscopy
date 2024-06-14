classdef (Abstract) Power_Meter < Device
    properties
        isConnected = false; % Flag set if device connected
        autoconnect = false; %Should device be automatically connected when instantiated?
        wavelength;
        meterPowerReading; % Power reading
        meterPowerUnit; % Power reading unit
    end
    
    methods
        %%The subclass initializer should call this superclass initializer
        %%before any further initialization steps.
        function obj = Power_Meter(Initializer)
            obj@Device(Initializer);
        end
    end
    
    methods (Abstract) %Must be implemented in subclass
        setWavelength(obj, value);
        readData(obj);
        connect(obj);
    end
end
