classdef Attenuator_Calibration_Data < handle
    properties
        fast_axis
        wavelength_list
        angle_list
        wavelength_mesh
        angle_mesh
        power_mat
    end

    methods
        function obj = Attenuator_Calibration_Data()
        end
        function relpower = getfastaxispower(obj, wavelength)
            relpower = obj.wavelength_fstpower(find(obj.wavelength_list == wavelength));
        end
        function Build_Mesh_Grid(obj)
            [obj.wavelength_mesh, obj.angle_mesh] = meshgrid(obj.wavelength_list, obj.angle_list);
            obj.power_mat = zeros(size(obj.wavelength_mesh'));
        end
        function add_to_power_mat(obj, wavelength, angle, data)
            obj.power_mat(wavelength == obj.wavelength_list, angle == obj.angle_list) = data;
        end
        function angle = HWP_angle(obj, wavelength, power)
            angle = griddata(obj.wavelength_mesh, obj.power_mat', obj.angle_mesh, wavelength, power, 'cubic');
        end
    end
end
