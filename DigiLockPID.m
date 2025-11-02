classdef DigiLockPID < handle
    % DigiLockPID - PID Controller module for DigiLock 110
    %
    % CORRECTED VERSION with proper RCI command syntax
    
    properties (Access = private)
        parent      % Parent DigiLock110 object
        pidNumber   % PID controller number (1 or 2)
    end
    
    properties (Constant)
        ValidInputs = {'main in', 'aux in', 'li out', 'pdh out'};
        ValidOutputs = {'main out', 'aux out', 'sc110 out', 'aio1 out', 'aio2 out'};
    end
    
    methods
        function obj = DigiLockPID(parent, pidNumber)
            if ~ismember(pidNumber, [1, 2])
                error('DigiLockPID:InvalidNumber', ...
                    'PID number must be 1 or 2');
            end
            
            obj.parent = parent;
            obj.pidNumber = pidNumber;
        end
        
        function cmdBase = getCommandBase(obj)
            % Get command prefix for this PID
            cmdBase = sprintf('pid%d', obj.pidNumber);
        end
        
        function setInput(obj, input)
            % Set input channel
            % RCI Command: pid1:input=main in
            input = lower(strrep(input, ' ', ' ')); % Keep spaces, lowercase
            if ~ismember(input, obj.ValidInputs)
                error('DigiLockPID:InvalidInput', ...
                    'Invalid input. Must be: %s', ...
                    strjoin(obj.ValidInputs, ', '));
            end
            
            cmd = sprintf('%s:input=%s', obj.getCommandBase(), input);
            obj.parent.write(cmd);
        end
        
        function input = getInput(obj)
            % Get current input channel
            % RCI Command: pid1:input?
            cmd = sprintf('%s:input?', obj.getCommandBase());
            input = obj.parent.query(cmd);
        end
        
        function setOutput(obj, output)
            % Set output channel
            % RCI Command: pid1:output=main out
            output = lower(strrep(output, ' ', ' ')); % Keep spaces, lowercase
            
            % Special handling for SC110
            if strcmpi(output, 'sc110')
                output = 'sc110 out';
            end
            
            if ~ismember(output, obj.ValidOutputs)
                error('DigiLockPID:InvalidOutput', ...
                    'Invalid output. Must be: %s', ...
                    strjoin(obj.ValidOutputs, ', '));
            end
            
            cmd = sprintf('%s:output=%s', obj.getCommandBase(), output);
            obj.parent.write(cmd);
        end
        
        function output = getOutput(obj)
            % Get current output channel
            % RCI Command: pid1:output?
            cmd = sprintf('%s:output?', obj.getCommandBase());
            output = obj.parent.query(cmd);
        end
        
        function setGain(obj, gain)
            % Set overall gain
            % RCI Command: pid1:gain=5.0
            cmd = sprintf('%s:gain=%.6f', obj.getCommandBase(), gain);
            obj.parent.write(cmd);
        end
        
        function gain = getGain(obj)
            % Get overall gain
            % RCI Command: pid1:gain?
            cmd = sprintf('%s:gain?', obj.getCommandBase());
            gain = obj.parent.queryNumeric(cmd);
        end
        
        function setP(obj, pGain)
            % Set proportional gain
            % RCI Command: pid1:proportional=1.0
            cmd = sprintf('%s:proportional=%.6f', obj.getCommandBase(), pGain);
            obj.parent.write(cmd);
        end
        
        function pGain = getP(obj)
            % Get proportional gain
            % RCI Command: pid1:proportional?
            cmd = sprintf('%s:proportional?', obj.getCommandBase());
            pGain = obj.parent.queryNumeric(cmd);
        end
        
        function setI(obj, iGain)
            % Set integral gain
            % RCI Command: pid1:integral=0.3
            cmd = sprintf('%s:integral=%.6f', obj.getCommandBase(), iGain);
            obj.parent.write(cmd);
        end
        
        function iGain = getI(obj)
            % Get integral gain
            % RCI Command: pid1:integral?
            cmd = sprintf('%s:integral?', obj.getCommandBase());
            iGain = obj.parent.queryNumeric(cmd);
        end
        
        function setD(obj, dGain)
            % Set derivative gain
            % RCI Command: pid1:differential=0.05
            cmd = sprintf('%s:differential=%.6f', obj.getCommandBase(), dGain);
            obj.parent.write(cmd);
        end
        
        function dGain = getD(obj)
            % Get derivative gain
            % RCI Command: pid1:differential?
            cmd = sprintf('%s:differential?', obj.getCommandBase());
            dGain = obj.parent.queryNumeric(cmd);
        end
        
        function setICutoff(obj, frequency)
            % Set integral cutoff frequency (PID 1 only)
            % RCI Command: pid1:integral:cutoff:frequency=100
            
            if obj.pidNumber ~= 1
                warning('DigiLockPID:NotPID1', ...
                    'I cutoff only available for PID 1');
                return;
            end
            
            cmd = sprintf('%s:integral:cutoff:frequency=%.6f', obj.getCommandBase(), frequency);
            obj.parent.write(cmd);
            
            % Enable the cutoff
            cmd = sprintf('%s:integral:cutoff:enable=true', obj.getCommandBase());
            obj.parent.write(cmd);
        end
        
        function freq = getICutoff(obj)
            % Get integral cutoff frequency (PID 1 only)
            % RCI Command: pid1:integral:cutoff:frequency?
            
            if obj.pidNumber ~= 1
                freq = [];
                return;
            end
            
            cmd = sprintf('%s:integral:cutoff:frequency?', obj.getCommandBase());
            freq = obj.parent.queryNumeric(cmd);
        end
        
        function setSetpoint(obj, setpoint)
            % Set controller setpoint
            % RCI Command: pid1:setpoint=0
            cmd = sprintf('%s:setpoint=%.6f', obj.getCommandBase(), setpoint);
            obj.parent.write(cmd);
        end
        
        function setpoint = getSetpoint(obj)
            % Get controller setpoint
            % RCI Command: pid1:setpoint?
            cmd = sprintf('%s:setpoint?', obj.getCommandBase());
            setpoint = obj.parent.queryNumeric(cmd);
        end
        
        function setSign(obj, sign)
            % Set controller polarity
            % RCI Command: pid1:sign=true (for POS) or =false (for NEG)
            
            sign = upper(sign);
            if strcmp(sign, 'POS')
                boolVal = 'true';
            elseif strcmp(sign, 'NEG')
                boolVal = 'false';
            else
                error('DigiLockPID:InvalidSign', ...
                    'Sign must be POS or NEG');
            end
            
            cmd = sprintf('%s:sign=%s', obj.getCommandBase(), boolVal);
            obj.parent.write(cmd);
        end
        
        function sign = getSign(obj)
            % Get controller polarity
            % RCI Command: pid1:sign?
            cmd = sprintf('%s:sign?', obj.getCommandBase());
            response = obj.parent.query(cmd);
            
            % Convert boolean response to POS/NEG
            if strcmpi(response, 'true') || strcmpi(response, '1')
                sign = 'POS';
            else
                sign = 'NEG';
            end
        end
        
        function setSlope(obj, slope)
            % Set locking slope direction
            % RCI Command: pid1:slope=true (for POS) or =false (for NEG)
            
            slope = upper(slope);
            if strcmp(slope, 'POS')
                boolVal = 'true';
            elseif strcmp(slope, 'NEG')
                boolVal = 'false';
            else
                error('DigiLockPID:InvalidSlope', ...
                    'Slope must be POS or NEG');
            end
            
            cmd = sprintf('%s:slope=%s', obj.getCommandBase(), boolVal);
            obj.parent.write(cmd);
        end
        
        function slope = getSlope(obj)
            % Get locking slope direction
            % RCI Command: pid1:slope?
            cmd = sprintf('%s:slope?', obj.getCommandBase());
            response = obj.parent.query(cmd);
            
            % Convert boolean response to POS/NEG
            if strcmpi(response, 'true') || strcmpi(response, '1')
                slope = 'POS';
            else
                slope = 'NEG';
            end
        end
        
        function setLimits(obj, minVal, maxVal)
            % Set output limits
            % RCI Commands: pid1:limit:min=-5, pid1:limit:max=5, pid1:limit:enable=true
            
            cmd = sprintf('%s:limit:min=%.6f', obj.getCommandBase(), minVal);
            obj.parent.write(cmd);
            
            cmd = sprintf('%s:limit:max=%.6f', obj.getCommandBase(), maxVal);
            obj.parent.write(cmd);
            
            cmd = sprintf('%s:limit:enable=true', obj.getCommandBase());
            obj.parent.write(cmd);
        end
        
        function disableLimits(obj)
            % Disable output limits
            % RCI Command: pid1:limit:enable=false
            cmd = sprintf('%s:limit:enable=false', obj.getCommandBase());
            obj.parent.write(cmd);
        end
        
        function limits = getLimits(obj)
            % Get output limits
            cmd = sprintf('%s:limit:min?', obj.getCommandBase());
            limits.min = obj.parent.queryNumeric(cmd);
            
            cmd = sprintf('%s:limit:max?', obj.getCommandBase());
            limits.max = obj.parent.queryNumeric(cmd);
            
            cmd = sprintf('%s:limit:enable?', obj.getCommandBase());
            response = obj.parent.query(cmd);
            limits.enabled = strcmpi(response, 'true') || strcmpi(response, '1');
        end
        
        function lock(obj)
            % Engage PID controller (start locking)
            % RCI Command: pid1:lock:enable=true
            cmd = sprintf('%s:lock:enable=true', obj.getCommandBase());
            obj.parent.write(cmd);
        end
        
        function unlock(obj)
            % Disengage PID controller (stop locking)
            % RCI Command: pid1:lock:enable=false
            cmd = sprintf('%s:lock:enable=false', obj.getCommandBase());
            obj.parent.write(cmd);
        end
        
        function status = getLockStatus(obj)
            % Get lock status
            % RCI Command: pid1:lock:state?
            cmd = sprintf('%s:lock:state?', obj.getCommandBase());
            response = obj.parent.query(cmd);
            status = strcmpi(response, 'true') || strcmpi(response, '1');
        end
        
        function hold(obj, enable)
            % Set hold state
            % RCI Command: pid1:lock:hold=true/false
            
            if enable
                state = 'true';
            else
                state = 'false';
            end
            
            cmd = sprintf('%s:lock:hold=%s', obj.getCommandBase(), state);
            obj.parent.write(cmd);
        end
        
        function status = getHoldStatus(obj)
            % Get hold status
            % RCI Command: pid1:hold:state?
            cmd = sprintf('%s:hold:state?', obj.getCommandBase());
            response = obj.parent.query(cmd);
            status = strcmpi(response, 'true') || strcmpi(response, '1');
        end
        
        function params = getAll(obj)
            % Get all PID parameters as a struct
            params.input = obj.getInput();
            params.output = obj.getOutput();
            params.gain = obj.getGain();
            params.P = obj.getP();
            params.I = obj.getI();
            params.D = obj.getD();
            
            if obj.pidNumber == 1
                params.ICutoff = obj.getICutoff();
            end
            
            params.setpoint = obj.getSetpoint();
            params.sign = obj.getSign();
            params.slope = obj.getSlope();
            params.limits = obj.getLimits();
            params.locked = obj.getLockStatus();
            params.hold = obj.getHoldStatus();
        end
    end
end
