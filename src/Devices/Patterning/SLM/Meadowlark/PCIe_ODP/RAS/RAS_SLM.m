classdef RAS_SLM < Meadowlark_PCIe_SLM_ODP
    properties (Transient)
        cell_groups
        cell_group_index
        cell_group_ref
        hold_cell_group
        custom_lut_loaded

        tcp_socket
    end
    properties
        LUT
        LUT_Stack
        wavelength
        tform_stack
        cfcl_tform
        camera_ref=true;
    end

    methods
        function obj = RAS_SLM(Initializer)
            obj@Meadowlark_PCIe_SLM_ODP(Initializer);
            obj.LUT_Stack=obj.Initializer.LUT_Stack;
            obj.debug_mode=0;
            obj.tcp_socket=tcpclient('128.103.90.235',3000);
            obj.Dimensions=[512 512];
        end

         function load_custom_lut(obj,wavelength)
            obj.load_linear_lut(); %Linearize onboard LUT
            obj.LUT=obj.LUT_Stack.GetLUT(wavelength);
            obj.custom_lut_loaded=true;
         end

         function set_tform(obj,wavelength)
            obj.tform=obj.tform_stack.GetTform(wavelength);
         end
         
         function load_1030_lut(obj)
            lut_file=fullfile('C:\Program Files\Meadowlark Optics\Blink OverDrive Plus\LUT Files\LUT-1030.lut');
            calllib('Blink_SDK_C', 'Load_LUT_file', obj.sdk, 1, lut_file);
            obj.custom_lut_loaded=false;
         end

         function load_linear_lut(obj)
            lut_file=fullfile('C:\Program Files\Meadowlark Optics\Blink OverDrive Plus\LUT Files\linear.lut');
            calllib('Blink_SDK_C', 'Load_LUT_file', obj.sdk, 1, lut_file);
            obj.custom_lut_loaded=false;
         end

         function Display_LUT_Cal(obj,raw_val)
            final_image=zeros(512,512);
            final_image(1:end,mod((1:end)-1,8)<4)=raw_val;
            if obj.debug_mode==0
                calllib('Blink_SDK_C', 'Write_image', obj.sdk, 1, final_image',512,0,0,5000);
            else
                imagesc(obj.demo_ax(1),final_image);
                colormap(obj.demo_ax(1),'gray');
                imagesc(obj.demo_ax(3),imwarp(obj.Target_Est,invert(obj.tform),'OutputView',imref2d([2048 2048])));
                colormap(obj.demo_ax(3),'jet');
            end
         end
         
         function Display_Masked_LUT_Cal(obj,raw_val,onrow)
            final_image=zeros(512,512);
            final_image(onrow,mod((1:end)-1,8)<4)=raw_val;
            if obj.debug_mode==0
                calllib('Blink_SDK_C', 'Write_image', obj.sdk, 1, final_image',512,0,0,5000);
            else
                imagesc(obj.demo_ax(1),final_image);
                colormap(obj.demo_ax(1),'gray');
                imagesc(obj.demo_ax(3),imwarp(obj.Target_Est,invert(obj.tform),'OutputView',imref2d([2048 2048])));
                colormap(obj.demo_ax(3),'jet');
            end
         end

         function DisplayX(obj)
            for i=1:512
                if mod(i,2)==0
                    freq=ceil(i/4);
                else
                    freq=ceil(128-i/4);
                end
                obj.Z_GS(i,:)=angle(exp(1i*(0:511)*2*pi*freq/512));
            end
            obj.Write_Static();
         end

        function obj=Calibration_Display(obj,options)
             arguments
                obj RAS_SLM
                options.width=2;
                options.freq=64;
                options.offset=0;
             end
             width=options.width;
             freq=options.freq;
             offset=options.offset;
             for i=1:512
                 if (~(mod(i,width)<width/2) && offset==0) || ((mod(i,width)<width/2) && offset==1)
                     obj.Z_GS(i,:)=angle(exp(1i*(0:511)*2*pi*freq/512));
                 else
                     obj.Z_GS(i,:)=zeros(1,512);
                 end
             end
             obj.Write_Static();
        end

        function Cal_TForm(obj)
            fixed=imgaussfilt(obj.GenTargetFromSpots(obj.calpoints,obj.Dimensions,10),5);
            roi=drawpolyline(obj.tax);
            display(roi.Position)
            if isMATLABReleaseOlderThan("R2022b")
                t_est = estimateGeometricTransform(roi.Position,[obj.calpoints(:,2) obj.calpoints(:,1)],...
              'affine'); %old pre-R2022b convention
            else
                t_est = estgeotform2d(roi.Position,[obj.calpoints(:,2) obj.calpoints(:,1)],...
              'affine'); %new premultiply convention
            end
            tform_out=obj.RefT(double(fixed),obj.testimage,5,t_est,obj.refimage.ref2d);
            obj.tform=tform_out;
            obj.Initializer.tform=tform_out.T;
            delete(roi);
            if obj.debug_mode==1
                imagesc(obj.demo_ax(2),obj.Target);
            end
        end

        function obj=GenROI(obj,options)
          arguments
            obj Patterning_Device
            options.testimage=obj.testimage
            options.ax=obj.tax;
            options.smoothing (1,1) double = obj.smoothing
            options.ROI_Type string = obj.ROI_Type
            options.append logical = obj.append_mode
            options.use_cam = false;
            options.hold_cell_group=obj.hold_cell_group
            options.camera_ref=true
            options.confocal_device=[]
          end
           transform=obj.tform;
           Rsnap=obj.refimage.ref2d;

           switch options.ROI_Type
             case 'points'
                roi=drawpolyline(obj.tax);
                i=roi.Position(:,1);
                j=roi.Position(:,2);

                [xcam,ycam]=transformPointsInverse(obj.refimage.tform,i,j);
                [x,y]=transformPointsForward(transform,xcam,ycam);
                Target=obj.GenTargetFromSpots([y,x],obj.Dimensions,...
                    options.smoothing);
                %[x,y]=transformPointsForward(transform,j,i);
                %Target=obj.GenTargetFromSpots([y,x],obj.Dimensions,...
                %options.smoothing);
             case 'polyedge'
                roi=drawpolyline(obj.tax);
                rmask=imgaussfilt(double(createMask(roi)),1);
                Rfixed = imref2d([obj.Dimensions(2) obj.Dimensions(1)]);
                Rcam=imref2d([2048 2048]);%Added
                tmask_cam=imwarp(rmask,Rsnap,invert(obj.refimage.tform),'OutputView',Rcam); %Added
                %tmask=imwarp(rmask,transform,'OutputView',Rfixed);
                tmask=imwarp(tmask_cam,transform,'OutputView',Rfixed);
                Target=imgaussfilt(double(tmask),.5);
                t_threshold=max(Target(:))/3;
                for i=1:512
                    tvec=Target(i,:);
                    tind=find(tvec==max(tvec));
                    if Target(i,tind)>0
                        Target(i,:)=0;
                        Target(i,tind)=1;
                    else
                        Target(i,:)=0;
                    end
                end
             case 'polyregion'
                roi=drawpolygon(obj.tax);
                rmask=createMask(roi);
                Rfixed = imref2d([obj.Dimensions(2) obj.Dimensions(1)]);
                tmask=imwarp(rmask,transform,'OutputView',Rfixed);
                if options.smoothing==0
                    Target=tmask;
                else
                    Target=imgaussfilt(double(tmask),options.smoothing);
                end
             otherwise
                disp('Invalid ROI type. Defaulting to points.')
                roi=drawpolyline(obj.tax);
                i=roi.Position(:,1);
                j=roi.Position(:,2);
                [x,y]=transformPointsForward(transform,i,j);
                Target=obj.GenTargetFromSpots([y,x],obj.Dimensions,options.smoothing);
           end
           rowcheck=max(Target,1);
           if options.append
             obj.Target = obj.Target./max(obj.Target(:)) + Target./max(Target(:));
             obj.Target = obj.Target./max(obj.Target(:));

            if options.hold_cell_group
               obj.cell_groups(obj.cell_group_index).indices=[obj.cell_groups(obj.cell_group_index).indices find(rowcheck>0)];
               obj.cell_group_ref{obj.cell_group_index}=obj.cell_group_ref{obj.cell_group_index}+double(Target>0);
            else
               obj.cell_group_index=obj.cell_group_index+1;
               obj.cell_groups(obj.cell_group_index).indices=find(rowcheck>0);
               obj.cell_group_ref{obj.cell_group_index}=double(Target>0);
            end
          else
             obj.Target = Target;
             obj.cell_groups=struct();
             obj.cell_group_index=1;
             obj.cell_group_ref={};
             obj.cell_group_ref{1}=double(Target>0);
             obj.cell_groups(1).indices=find(rowcheck>0);
          end

          delete(roi);
        end

        function obj=Write_Static(obj,options)
            arguments
                obj RAS_SLM
                options.StackSelect double=0
            end
            if options.StackSelect==0
                Z_GS_loc=obj.Z_GS;
            else
                Z_GS_loc=obj.Hologram_Stack(options.StackSelect);
            end
               Shifted_Image=obj.ShiftImage(Z_GS_loc);
               Z_SUM = wrapToPi(Shifted_Image);
               Z_TOTAL = uint8(mod(256*(Z_SUM+pi)/(2*pi),256));
               if obj.custom_lut_loaded
                    Z_TOTAL=obj.ApplyLUT(Z_TOTAL,obj.LUT);
               end
               final_image = uint8(mod(Z_TOTAL,256));
               obj.Project(final_image);
        end

        function Shifted_Image=ShiftImage(obj,Z_GS) %Override from SLM base class
            dispX = -256;
            X=repmat(1:512,[512,1]);
            r=X+dispX;
            Z_Defocus=(2*r.^2-1);
            Z_ComaX= 3*r.^3-2*r;
            Z_Spherical= 6*r.^4-6*r.^2;

            if ~isempty(obj.Defocus)
                Z5 = angle(exp(-1i*(Z_Defocus.*obj.Defocus*1e-5)));%Recommended value: ~-10 to 10
            else
                Z5 = 0;
            end

            if ~isempty(obj.ComaX)
                Z6 = angle(exp(-1i*(Z_ComaX.*obj.ComaX*1e-8))); %Recommended value: ~0.1 to 100
            else
                Z6 = 0;
            end

            if ~isempty(obj.Spherical)
                Z8 = angle(exp(-1i*(Z_Spherical.*obj.Spherical*1e-12)));%Recommended value: ~0.1 to 10
            else
                Z8 = 0;
            end

            Shifted_Image =  Z_GS + Z5 + Z6+ Z8;
            
        end
        
        function Load_Ref_Im(obj) %Override for generic patterning device to account for the remote session.
            drawnow;pause(.1);
            if ~isvalid(obj.tax)
              figure
              tax=gca;
              obj.tax=tax;
            end
            flush(obj.tcp_socket);
            if(obj.camera_ref)
                obj.tcp_socket.writeline(char("Get_Snap"));
                snap=uint16(read(obj.tcp_socket,2048*2048,"uint16"));
                drawnow;pause(.1);
                obj.testimage=double(reshape(snap,[2048,2048]));
                drawnow;pause(.1);
                obj.tax.XLim=[0 size(obj.testimage,2)];
                obj.tax.YLim=[0 size(obj.testimage,1)];
            else
                obj.tcp_socket.writeline(char("Get_Cfcl_Snap"));
                sizeinfo=read(obj.tcp_socket,2,"double");
                tforminfo=reshape(read(obj.tcp_socket,9,"double"),[3 3]);
                obj.testimage=reshape(read(obj.tcp_socket,sizeinfo(1)*sizeinfo(2),"double"),sizeinfo);
                drawnow;pause(.1);
                obj.tax.XLim=[0 size(obj.testimage,2)];
                obj.tax.YLim=[0 size(obj.testimage,1)];
            end
            drawnow;pause(.1);
            obj.I.CData=obj.testimage;
            drawnow;pause(.1);
        end

        function success = Project_Cal_Pattern(obj)
            Target=obj.GenTargetFromSpots(obj.calpoints,obj.Dimensions);
            obj.Target=Target;
            obj.SLM_genholo();
            success = 1;
        end

    end
    methods(Static)
        function res=SetCoverVoltage(volts)
            display('ignoring coverglass voltage set for RAS_SLM');
            res=1;
        end
    end

    methods(Static,Hidden=true)
        function [Z_GS,Target_Est]=SLM_routine(Target,Spot_Width,numiterations,progressbar) %Overrides Default
            [Z_GS,Target_Est]=RAS_SLM_routine(Target,numiterations,Spot_Width);
        end
        function Target=GenTargetFromSpots(spotcoords,Dimensions,~)
           spotcoords=round(spotcoords);
           OOB_Mask=(spotcoords(:,1)<1)|(spotcoords(:,2)<1)|(spotcoords(:,2)>128)|(spotcoords(:,1)>512);
           spotcoords(OOB_Mask,:)=[];
           ind=sub2ind(Dimensions,spotcoords(:,1),spotcoords(:,2));
           Target=zeros(512,512);
           Target(ind)=1;
        end

        function out=ApplyLUT(in,LUT)
            arguments
                in
                LUT WL_LUT
            end
            out=zeros(size(in));
            rows_per_group=size(in,1)/LUT.numregions;
            for i=1:LUT.numregions
                LUTVec=real(LUT.LUT_Ref(i,:));
                out((1:rows_per_group)+(i-1)*rows_per_group,:)=LUTVec(round(in((1:rows_per_group)+(i-1)*rows_per_group,:)+1));
            end
        end

    end
end