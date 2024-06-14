classdef (Abstract) SLM_Device < Patterning_Device
    %Cohen Lab SLM_Device Controller (prototype version)
    %Authors: Hunter Davis and David Wong-Campos
    %Contact: huntercoledavis@gmail.com,jwongcampos@gmail.com
    
        properties
            %Hologram Information
            TiltX double
            TiltY double
            AstX double
            AstY double
            Defocus double
            ComaX double
            ComaY double
            Spherical double
            Beam_Waist double
            WavefrontCorrection
            Z_GS
            
            holoiterations
            progressbar
            Hologram_Stack
            Stack_Frame_Number
            Target_Est
        end
    
        methods
            function obj=SLM_Device(Initializer)
                obj@Patterning_Device(Initializer);
                obj.smoothing=1.0;
                obj.calthresh=10;
                obj.Hologram_Stack=struct();
                obj.Stack_Frame_Number=1;
                if obj.debug_mode==1
                figure
                subplot(1,3,1)
                title('Simulated SLM Face')
                colormap(gray);
                obj.demo_ax(1)=gca;
                subplot(1,3,2)
                title('Target in SLM coords')
                obj.demo_ax(2)=gca;
                subplot(1,3,3)
                obj.demo_ax(3)=gca;
                title('Simulated image plane')
                end
                obj.holoiterations=100;
                obj.progressbar=[];
            end
    
            function Add_Pattern_to_Alignment(obj,name)
                obj.Alignment_Pattern_Stack(end+1).pattern=obj.Z_GS;
                obj.Alignment_Pattern_Stack(end).name=name;
            end
    
            function Project_Aligment_Pattern(obj,name)
                pattern=obj.Alignment_Pattern_Stack(strcmp([obj.Alignment_Pattern_Stack.name],name)).pattern;
                if ~isempty(pattern)
                    obj.Z_GS=pattern;
                    obj.Write_Static();
                else
                    display('Pattern not found')
                end
            end
    
            function Load_Inits(obj)
                Load_Inits@Patterning_Device(obj);
                % Aberrations:
                obj.TiltY=obj.Initializer.TiltY;
                obj.TiltX=obj.Initializer.TiltX;
                obj.AstX=obj.Initializer.AstX;
                obj.AstY=obj.Initializer.AstY;
                obj.Defocus=obj.Initializer.Defocus;
                obj.ComaX=obj.Initializer.ComaX;
                obj.ComaY=obj.Initializer.ComaY;
                obj.Spherical=obj.Initializer.Spherical;
                obj.Beam_Waist=obj.Initializer.Beam_Waist;
                obj.gpu_available=false;
                obj.WavefrontCorrection=[];%obj.Initializer.WavefrontCorrection;
            end
            function set.TiltX(obj,val)
                obj.TiltX = val;
                if obj.SDK_Loaded
                    obj.Write_Static();
                end
            end
            function set.TiltY(obj,val)
                obj.TiltY = val;
                if obj.SDK_Loaded
                    obj.Write_Static();
                end
            end
            function set.AstX(obj,val)
                obj.AstX = val;
                if obj.SDK_Loaded
                    obj.Write_Static();
                end
            end
            function set.AstY(obj,val)
                obj.AstY = val;
                if obj.SDK_Loaded
                    obj.Write_Static();
                end
            end
            function set.Defocus(obj,val)
                obj.Defocus = val;
                if obj.SDK_Loaded
                    obj.Write_Static();
                end
            end
            function set.ComaX(obj,val)
                obj.ComaX = val;
                if obj.SDK_Loaded
                    obj.Write_Static();
                end
            end
            function set.ComaY(obj,val)
                obj.ComaY = val;
                if obj.SDK_Loaded
                    obj.Write_Static();
                end
            end
             function set.Spherical(obj,val)
                obj.Spherical = val;
                if obj.SDK_Loaded
                    obj.Write_Static();
                end
             end
            function success = SLM_genholo(obj,options)
              arguments
                obj SLM_Device
                options.Target (:,:) double = obj.Target
                options.gpu_avail (1,1) logical = obj.gpu_available
                options.Beam_Waist (1,1) {mustBeNumeric} = obj.Beam_Waist
                options.numiterations   (1,1) {mustBeNumeric} = obj.holoiterations
                options.write_when_complete (1,1) logical = 1
                options.append_to_stack (1,1) logical = 0
                options.clear_stack (1,1) logical = 1
    
              end
              Target=options.Target;
              obj.Target=options.Target;
              if obj.debug_mode==1
                imagesc(obj.demo_ax(2),obj.Target);
              end
              [obj.Z_GS,obj.Target_Est]=obj.SLM_routine(Target,options.Beam_Waist,options.numiterations,obj.progressbar);
              if options.write_when_complete
                  if exist("gpuDeviceCount") && gpuDeviceCount("available")
                    obj.Z_GS = gather(obj.Z_GS);   
                    obj.Target_Est = gather(obj.Target_Est);
                  end
                  obj.Write_Static();
              end
              if options.append_to_stack
                if isempty(obj.Hologram_Stack)
                    obj.Hologram_Stack(1).frame=obj.Z_GS;
                else
                    obj.Hologram_Stack(numel(obj.Hologram_Stack)+1).frame=obj.Z_GS;
                end
              end
    
              if options.clear_stack
                obj.Hologram_Stack=struct();
                obj.Hologram_Stack(1).frame=obj.Z_GS;
                obj.Stack_Frame_Number=1;
              end
    
            success=1;
            end
    
            % Project stored calibration pattern. Optional num_points_to_show
            % argument allows for showing only a prefix subset of the full
            % calibration pattern (in order, e.g. to step through the
            % calibration pattern interactively point-by-point.
            function Project_Cal_Pattern(obj, num_points_to_show)
                arguments
                    obj SLM_Device;
                    num_points_to_show = -1;
                end
                if num_points_to_show < 0
                    num_points_to_show = size(obj.calpoints,1);
                end
                obj.Target=obj.GenTargetFromSpots(obj.calpoints(1:num_points_to_show,:),obj.Dimensions,2);
                obj.SLM_genholo();
            end
    
            function Write_Static(obj,options)
                arguments
                    obj SLM_Device
                    options.StackSelect double = 0
                end
                if options.StackSelect == 0
                    Z_GS_loc = obj.Z_GS;
                else
                    Z_GS_loc = obj.Hologram_Stack(options.StackSelect);
                end
                Shifted_Image = obj.ShiftImage(Z_GS_loc);
                Z_SUM = wrapToPi(Shifted_Image);
                obj.Project(Z_SUM);
            end
    
            function Shifted_Image = ShiftImage(obj,Z_GS) %Breaking this off to allow for overrides in subclasses
                width = size(obj.Target, 1);
                height = size(obj.Target, 2);
                [X,Y] = meshgrid(1:width, 1:height);
                % We will work in polar coordinates to be consistent with the
                % usual Zernike polynomials. I will center the 0 to the middle
                % of the matrix:
                dispX = -width/2;
                dispY = -height/2;
                Xp = X+dispX;
                Yp = Y+dispY;
                [theta,r] = cart2pol(Xp,Yp);
    
                % Zernike Polynomial for Tilts (pattern displacements)
                Z_TiltX =  r .* cos(theta);
                Z_TiltY =  r .* sin(theta);
    
                % Zernike Polynomial for Astigmatisms and defocus
                Z_AstigX =  r.^2 .* cos(2*theta);
                Z_Defocus =  (2.*r.^2 - 1);
                Z_AstigY =  r.^2 .* sin(2*theta);
    
                % Zernike Polynomial for Comma
                Z_ComaX =  (3*r.^3 - 2.*r) .* cos(theta);
                Z_ComaY =  (3*r.^3 - 2.*r) .* sin(theta);
    
                % Zernike Polynomial for Spherical Aberration
                Z_Spherical =  6*r.^4 - 6*r.^2 + 1;
    
                % Recommended values and fudge factors to keep reasonable final
                % values
                if ~isempty(obj.TiltX)
                    Z1 = angle(exp(1i*(Z_TiltX*obj.TiltX)))'; %Recommended value: ~0.1 to 3
                else
                    Z1 = 0;
                end
    
                if ~isempty(obj.TiltY)
                    Z2 = angle(exp(-1i*(Z_TiltY*obj.TiltY)))'; %Recommended value: ~0.1 to 3
                else
                    Z2 = 0;
                end
    
                if ~isempty(obj.AstX)
                    Z3 = angle(exp(-1i*(Z_AstigX*obj.AstX*1e-4)))'; %Recommended value: ~0.1 to 3, 1e-4 is just a fudge factor
                else
                    Z3 = 0;
                end
    
                if ~isempty(obj.AstY)
                    Z4 = angle(exp(-1i*(Z_AstigY*obj.AstY*1e-4)))'; %Recommended value: ~0.1 to 3, 1e-4 is just a fudge factor
                else
                    Z4 = 0;
                end
    
                if ~isempty(obj.Defocus)
                    Z5 = angle(exp(-1i*(Z_Defocus*obj.Defocus*1e-5)))';%Recommended value: ~1 to 10
                else
                    Z5 = 0;
                end
    
                if ~isempty(obj.ComaX)
                    Z6 = angle(exp(-1i*(Z_ComaX*obj.ComaX*1e-8)))'; %Recommended value: ~0.1 to 100
                else
                    Z6 = 0;
                end
    
                if ~isempty(obj.ComaY)
                    Z7 = angle(exp(-1i*(Z_ComaY*obj.ComaY*1e-8)))'; %Recommended value: ~0.1 to 100
                else
                    Z7 = 0;
                end
    
                if ~isempty(obj.Spherical)
                    Z8 = angle(exp(-1i*(Z_Spherical*obj.Spherical*1e-12)))';%Recommended value: ~0.1 to 10
                else
                    Z8 = 0;
                end
    
                Shifted_Image =  Z_GS + Z1 + Z2 + Z3 + Z4 + Z5 + Z6 + Z7 + Z8;
            end
            
    
        end
    
        methods(Abstract)
            Project(obj,Z_TOTAL);
        end
    
        methods(Static)
            function [Z_GS,Target_Est]=SLM_routine(Target,Beam_Waist,numiterations,progressbar) %Default Hologram Generation routine. Subclass implementation can override.
                width = size(Target,1);
                height = size(Target,2);
                [X,Y] = meshgrid(1:width,1:height);
                gauss = @(x0,y0,w0) exp(-((X-x0).^2+(Y-y0).^2)/w0.^2);
                Random_phase = 0.5*rand(width,height)* 2*pi;
    
                if exist("gpuDeviceCount") && gpuDeviceCount("available") %Swap CPU arrays for GPU arrays to accelerate when available
                  X=gpuArray(X);
                  Y=gpuArray(Y);
                  Target=gpuArray(Target);
                  A0 = gpuArray((gauss(width/2,height/2,Beam_Waist))'); %Input gaussian on the SLM
                  S1 = gpuArray(fft2(A0.*Random_phase));
                  trt=gpuArray(sqrt(complex(Target))/sum(Target(:)));
                  display('Using GPU')
                else
                    A0=(gauss(width/2,height/2,Beam_Waist))';
                    S1=fft2(A0.*Random_phase);
                    trt= sqrt(Target)/sum(Target(:));
                    %Target+0.1;
                end
                stbl=false;
                k=0;
                tic
                while k<numiterations
                  S2 = trt.*exp(1i*angle(S1));
                  S3 = ifft2(S2);
                  S4 = A0.*exp(1i*angle(S3));
                  S1 = fft2(S4);
                  k  = k+1;
                  if mod(k,round(numiterations*.1))==0 && ~isempty(progressbar)
                    progressbar.Value=k/numiterations*100;
                    drawnow
                  end
                end
                if ~isempty(progressbar)
                    progressbar.Value=100;
                end
                cc=corrcoef(abs(S1(:)),trt);
                toc
                display(['final cc:' num2str(cc(2))])
                Result_GS = ifft2(S1); %This gives the SLM's field
                Z_GS = angle(Result_GS);
                Target_Est=abs(S1);
            end
            function Target=GenTargetFromSpots(spotcoords,Dimensions,Width)
               [X,Y]=meshgrid(1:Dimensions(1),1:Dimensions(2));
               gauss = @(x0,y0,w0) exp(-((X-x0).^2+(Y-y0).^2)/w0.^2);
               Target=zeros(Dimensions)';
               for i=1:size(spotcoords,1)
                  Target=Target+gauss(spotcoords(i,1),spotcoords(i,2),Width);
               end
            end
        end
    end