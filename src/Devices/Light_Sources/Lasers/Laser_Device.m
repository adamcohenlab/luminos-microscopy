classdef (Abstract) Laser_Device < Device
    properties
        maxPower
        Wavelength
        SetPower
    end
    
    methods
        %%The subclass initializer should call this superclass initializer
        %%before any further initialization steps.
        function obj = Laser_Device(Initializer)
            obj@Device(Initializer);
        end
        
        %%This initialize_props function should be called after all other
        %%initialization steps to ensure that property values are correctly
        %%initialized to current device state.
        function obj = initialize_props(obj)
            obj.get("SetPower");
            obj.get("Wavelength");
            obj.get('maxPower');
        end
        
        %%Set methods---------------------------------------------------
        %%Every set method should also update the properties.
        %%--------------------------------------------------------------
        function set.SetPower(obj, value)
            obj.Set_pow(value);
            obj.SetPower = value;
        end
        
        %%Get methods-----------------------------------------------------
        %%Every get method should also update the properties.
        %%For any get function that refers to a non-constant parameter, the
        %%subclass should check the parameter from the device for every
        %%get.---------------------------------------------------------
        function wavelength = get.Wavelength(obj)
            wavelength = obj.Get_wav();
            obj.Wavelength = wavelength;
        end
        function wavelength = Get_wav(obj) %Placeholder just returns static parameter
            wavelength = obj.Wavelength;
        end
        
        function pow = get.SetPower(obj)
            pow = obj.Get_pow_set();
            %obj.SetPower = pow;
        end
        function pow = Get_pow(obj) %Placeholder just returns static parameter.
            pow = obj.SetPower;
        end
        
        function pow = get.maxPower(obj)
            pow = obj.Get_powLimits();
            pow = pow(2);
            obj.maxPower = pow;
        end
        function limits = Get_powLimits(obj)
            limits = [0, obj.maxPower];
        end
        
        function Start_JS(obj)
            obj.Start();
            
        end
        
        function Stop_JS(obj)
            obj.Stop();
            
        end
    end
    
    methods (Abstract) %Must be implemented in subclass
        Set_pow(obj, value)
        Start(obj)
        Stop(obj)
        Get_state(obj)
    end
end
