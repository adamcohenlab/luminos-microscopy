classdef DAQ_wfm < handle
    properties
        attached_func
        port
        name
        func_args
    end

    properties (SetAccess = private, SetObservable)
        func_arg_names
        func_prototype
    end

    methods
        function obj = DAQ_wfm()
        end
        function set.attached_func(obj, attached_func)
            obj.attached_func = attached_func;
            obj.Update_Func_Arg_Names(attached_func);
        end
        function Update_Func_Arg_Names(obj, attached_func)
            obj.func_prototype = Get_WFM_Inputs(attached_func);
            full_inputs = strsplit(obj.func_prototype, ',');
            full_inputs = full_inputs(2:end);
            full_inputs{end} = full_inputs{end}(1:end - 1);
            obj.func_arg_names = full_inputs;
        end
    end
end
