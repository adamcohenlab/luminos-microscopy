function [calstore, lambdamixed] = Calibrate_Power(obj, min_wavelength, max_wavelength)
calstore = Attenuator_Calibration_Data();
calstore.wavelength_list = min_wavelength:5:max_wavelength;
calstore.angle_list = 19:19 + 45;
calstore.Build_Mesh_Grid();
tic
lambdalist = min_wavelength:5:max_wavelength;
lambdamixed = lambdalist(randperm(numel(lambdalist)));
for lambda = lambdamixed
    fprintf('starting: %d nm \n', lambda);
    obj.Meter.Set_Scale('3');
    scale = 3;
    obj.OPA.wavelength = lambda;
    obj.Meter.dev.flush();
    obj.Meter.Set_Wavelength(lambda)
    obj.Attenuator.rotation_motor.moveto(19);
    pause(5)
    for angle = 19:19 + 45
        scale_reset = false;
        obj.Attenuator.rotation_motor.moveto(angle);
        dstore = zeros(1, 20);
        pause(2)
        for i = 1:20
            dstore(i) = obj.Meter.Read_Data();
        end
        mdstore = mean(dstore);
        calstore.add_to_power_mat(lambda, angle, mdstore);
        if mdstore < 1 && scale > 1
            resposne = obj.Meter.Set_Scale('1');
            scale = 1;
            scale_reset = true;
        end
        if mdstore < .3 && scale > .3
            resposne = obj.Meter.Set_Scale('300m');
            scale = .3;
            scale_reset = true;
        end
        if mdstore < .1 && scale > .1
            resposne = obj.Meter.Set_Scale('100m');
            scale = .1;
            scale_reset = true;
        end
        if scale_reset == true
            for i = 1:100
                dstore(i) = obj.Meter.Read_Data();
            end
            mdstore = mean(dstore);
            calstore.add_to_power_mat(lambda, angle, mdstore);
        end
        display(angle)
    end
    fprintf('finished: %d nm \n', lambda);
    toc
end
end