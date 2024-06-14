% Newport TRB25CC
classdef Newport_Motor_Controller < Linear_Controller
    properties (Constant, Hidden)
        nonblockingMoveCompletedDetectionStrategy = 'poll';
    end
    properties (Transient)
        motorAPI
        lowerLim
        upperLim
        backlashCor
        COMPORT string
        coarseStepSizeInit
        fineStepSizeInit
    end
    properties (SetObservable, AbortSet)
        pos % coarseStepSize, fineStepSize, z
        zStageFlag = true;
    end
    
    methods
        
        function obj = Newport_Motor_Controller(Initializers)
            obj = obj@Linear_Controller(Initializers);
            NET.addAssembly('Newport.CONEXCC.CommandInterface');
            obj.motorAPI = CommandInterfaceConexCC.ConexCC;
            obj.motorAPI.OpenInstrument(obj.Initializer.COMPORT);
            [flag,obj.lowerLim,~] = obj.motorAPI.SL_Get(1);
            if flag == -1, error('get lower limit (SL_Get) error');end
            %flag = obj.motorAPI.SR_Set(1,12); % This does not work correctly? Going to set upperLim manually in software
            %if flag == -1, error('set upper limit (SR_Get) error');end
            %[flag,obj.upperLim,~] = obj.motorAPI.SR_Get(1); 
            obj.upperLim = 12;  % manually set upper limit to 12 mm because motor gets stuck at around 15mm
            if flag == -1, error('get upper limit (SR_Get) error');end
            [flag,obj.backlashCor,~] = obj.motorAPI.BA_Get(1);
            if flag == -1, error('get backlash correction (BA_Get) error');end
            obj.motorAPI.OR(1); % Single home command sometimes gets ignored
            obj.motorAPI.PA_Set(1,2);
            flag = obj.motorAPI.OR(1); % Initialize in home positon = at highest position, 0mm
            if flag == -1, error('get homing (OR) error');end
            obj.pos = struct('zAbs', []);
            obj.pos.zAbs = obj.Get_Current_Position();
            obj.pos.coarseStepSize = obj.Initializer.coarseStepSizeInit; % Coarse step size in mm
            obj.pos.fineStepSize = obj.Initializer.fineStepSizeInit; % Fine step size in mm
        end
%         function Configure_Controller(obj)
%             obj.serial_com = serialport(obj.COMPORT, obj.baud, 'Timeout', obj.port_timeout);
%             obj.serial_com.configureTerminator("CR");
%             set(obj.serial_com, 'DataBits', 8);
%             set(obj.serial_com, 'FlowControl', 'none');
%             set(obj.serial_com, 'Parity', 'none');
%             set(obj.serial_com, 'StopBits', 1);
%             set(obj.serial_com, 'Timeout', 10);
%         end
        function success = Move_To_Position(obj, nextPositionStruct)
            success = -1;
            % position = z
            % disable tracking mode
            % correct for backlash when moving backwards
            obj.pos.coarseStepSize = nextPositionStruct(1);
            obj.pos.fineStepSize = nextPositionStruct(2);
            nextPosition = nextPositionStruct(3);
            assert(isnumeric(nextPosition),'moveTo position must be numeric')
            
            if nextPosition < obj.lowerLim
                error('target position below lower software limit.') % better stop here than in APT
            end
            if nextPosition > obj.upperLim
                error('target position above higher software limit') % better stop here than in APT
            end
            
            flag = obj.motorAPI.TK_Set(1,0);
            if flag == -1, error('tracking mode (TK_Set) error'); success = -1;end
            obj.pos.zAbs = obj.Get_Current_Position();
            
            if nextPosition < obj.pos.zAbs % backlash correction
                
                backlashCorPosition = max(nextPosition - obj.backlashCor,obj.lowerLim);
                
                flag = obj.motorAPI.PA_Set(1,backlashCorPosition);
                if flag == -1, error('set position (PA_Set) error'); success = -1;end
                while obj.isMoving;pause(.001);end % wait for move to complete. Control movement speed here?
                flag = obj.motorAPI.PA_Set(1,nextPosition);
                if flag == -1, error('set position (PA_Set) error'); success = -1;end
            else
                flag = obj.motorAPI.PA_Set(1,nextPosition);
                if flag == -1, error('set position (PA_Set) error'); success = -1; end
				while obj.isMoving;pause(.001);end % wait for move to complete. Control movement speed here?
            end
             success = 0;
             obj.pos.zAbs = obj.Get_Current_Position();
             %obj.Get_Current_Position()
        end

        function positionZ = Get_Current_Position(obj) % Get absolute motor position in mm. Top position is 0mm 
            [flag,positionZ,~] = obj.motorAPI.TP(1);
            if flag == -1, error('get position (TP) error');end
        end

        function positionZ = Get_Current_Position_Microns(obj) % Get absolute motor position in mm. Top position is 0mm 
            [flag,positionZ,~] = obj.motorAPI.TP(1);
            positionZ = positionZ * 1000; % Convert mm to um
            if flag == -1, error('get position (TP) error');end
        end

%         function moveToRel(obj,delta)
%             % enable tracking mode
%             assert(isnumeric(delta),'moveTo position must be numeric')
%             obj.pos.zAbs = obj.Get_Current_Position();
%             if delta + obj.pos.zAbs < obj.lowerLim
%                 error('target position below lower software limit') % better stop here than in APT
%             end
%             if delta + obj.pos.zAbs > obj.upperLim
%                 error('target position above higher software limit') % better stop here than in APT
%             end
%             
%             flag = obj.motorAPI.TK_Set(1,1);
%             if flag == -1, error('tracking mode (TK_Set) error');end
%             
%             flag = obj.motorAPI.PR_Set(1,delta);
%             if flag == -1, error('set position (PA_Set) error');end
%             obj.pos.zAbs = obj.Get_Current_Position();
% 
%             %obj.Get_Current_Position()
%         end

        % Persistent time since last error to avoid spamming 
        function moveToRel(obj, delta)
            persistent lastErrorTime
            throttleTime = 2; % Throttle time in seconds
        
            assert(isnumeric(delta), 'moveTo position must be numeric')
            obj.pos.zAbs = obj.Get_Current_Position();
        
            currentTime = now;
            if ~isempty(lastErrorTime) && (currentTime - lastErrorTime) * 24 * 60 * 60 < throttleTime
                return;
            end
            delta
            if (delta + obj.pos.zAbs < obj.lowerLim) && delta < 0
                lastErrorTime = now;
                error('Target position below lower software limit');
            end
            if (delta + obj.pos.zAbs > obj.upperLim) && delta > 0
                lastErrorTime = now;
                error('Target position above higher software limit');
            end
        
            flag = obj.motorAPI.TK_Set(1, 1);
            if flag == -1
                lastErrorTime = now;
                error('Tracking mode (TK_Set) error');
            end
        
            flag = obj.motorAPI.PR_Set(1, delta);
            if flag == -1
                lastErrorTime = now;
                error('Set position (PA_Set) error');
            end
        
            obj.pos.zAbs = obj.Get_Current_Position();
        end
        
        function stop(obj)
            flag = obj.motorAPI.ST(1);
            if flag == -1, error('stop command (ST) error');end
        end
        
        function movingFlag = isMoving(obj)
            [~,~,val] = obj.motorAPI.TS(1);
            movingFlag = str2double(string(val)) == 28;
        end
        
        function delete(obj)
            obj.motorAPI.CloseInstrument;
%             if flag == -1, error('PA_Set error');end
        end
    end
end