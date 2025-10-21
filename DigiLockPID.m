classdef DigiLockPID < handle
    % DigiLockPID - PID Controller module for DigiLock 110
    %
    % Controls PID 1 or PID 2 feedback controllers with:
    %   - Proportional, Integral, and Derivative gains
    %   - Setpoint adjustment
    %   - Output limits
    %   - Hold and lock functions
    %
    % Usage:
    %   dl.pid1.setGain(10);
    %   dl.pid1.setP(1.0);
    %   dl.pid1.setI(0.5);
    %   dl.pid1.setD(0.1);
    %   dl.pid1.setSetpoint(0);
    %   dl.pid1.lock();
    
    properties (Access = private)
        parent      % Parent DigiLock110 object
        pidNumber   % PID controller number (1 or 2)
    end
    
    properties (Constant)
        ValidInputs = {'MainIn', 'AuxIn', 'LIOut', 'PDHOut'};
        ValidOutputs = {'MainOut', 'AuxOut', 'SC110', 'AIO1', 'AIO2'};
        ValidSigns = {'POS', 'NEG'};
        ValidSlopes = {'POS', 'NEG'};
    end
    
    methods
        function obj = DigiLockPID(parent, pidNumber)
            % Constructor
            %
            % Parameters:
            %   parent - Parent DigiLock110 object
            %   pidNumber - Controller number (1 or 2)
            
            if ~ismember(pidNumber, [1, 2])
                error('DigiLockPID:InvalidNumber', ...
                    'PID number must be 1 or 2');
            end
            
            obj.parent = parent;
            obj.pidNumber = pidNumber;
        end
        
        function cmdBase = getCommandBase(obj)
            % Get command prefix for this PID
            cmdBase = sprintf('PID%d', obj.pidNumber);
        end
        
        function setInput(obj, input)
            % Set input channel
            %
            % Parameters:
            %   input - Input channel name
            
            input = upper(strrep(input, ' ', ''));
            if ~ismember(input, upper(obj.ValidInputs))
                error('DigiLockPID:InvalidInput', ...
                    'Invalid input. Must be: %s', ...
                    strjoin(obj.ValidInputs, ', '));
            end
            
            cmd = sprintf('%s:INP %s', obj.getCommandBase(), input);
            obj.parent.write(cmd);
        end
        
        function input = getInput(obj)
            % Get current input channel
            cmd = sprintf('%s:INP?', obj.getCommandBase());
            input = obj.parent.query(cmd);
        end
        
        function setOutput(obj, output)
            % Set output channel
            %
            % Parameters:
            %   output - Output channel name
            
            output = upper(strrep(output, ' ', ''));
            if ~ismember(output, upper(obj.ValidOutputs))
                error('DigiLockPID:InvalidOutput', ...
                    'Invalid output. Must be: %s', ...
                    strjoin(obj.ValidOutputs, ', '));
            end
            
            cmd = sprintf('%s:OUTP %s', obj.getCommandBase(), output);
            obj.parent.write(cmd);
        end
        
        function output = getOutput(obj)
            % Get current output channel
            cmd = sprintf('%s:OUTP?', obj.getCommandBase());
            output = obj.parent.query(cmd);
        end
        
        function setGain(obj, gain)
            % Set overall gain
            %
            % Parameters:
            %   gain - Overall gain value
            
            cmd = sprintf('%s:GAIN %.6f', obj.getCommandBase(), gain);
            obj.parent.write(cmd);
        end
        
        function gain = getGain(obj)
            % Get overall gain
            cmd = sprintf('%s:GAIN?', obj.getCommandBase());
            gain = obj.parent.queryNumeric(cmd);
        end
        
        function setP(obj, pGain)
            % Set proportional gain
            %
            % Parameters:
            %   pGain - Proportional gain value
            
            cmd = sprintf('%s:P %.6f', obj.getCommandBase(), pGain);
            obj.parent.write(cmd);
        end
        
        function pGain = getP(obj)
            % Get proportional gain
            cmd = sprintf('%s:P?', obj.getCommandBase());
            pGain = obj.parent.queryNumeric(cmd);
        end
        
        function setI(obj, iGain)
            % Set integral gain
            %
            % Parameters:
            %   iGain - Integral gain value
            
            cmd = sprintf('%s:I %.6f', obj.getCommandBase(), iGain);
            obj.parent.write(cmd);
        end
        
        function iGain = getI(obj)
            % Get integral gain
            cmd = sprintf('%s:I?', obj.getCommandBase());
            iGain = obj.parent.queryNumeric(cmd);
        end
        
        function setD(obj, dGain)
            % Set derivative gain
            %
            % Parameters:
            %   dGain - Derivative gain value
            
            cmd = sprintf('%s:D %.6f', obj.getCommandBase(), dGain);
            obj.parent.write(cmd);
        end
        
        function dGain = getD(obj)
            % Get derivative gain
            cmd = sprintf('%s:D?', obj.getCommandBase());
            dGain = obj.parent.queryNumeric(cmd);
        end
        
        function setICutoff(obj, frequency)
            % Set integral cutoff frequency (PID 1 only)
            %
            % Parameters:
            %   frequency - Cutoff frequency in Hz
            
            if obj.pidNumber ~= 1
                warning('DigiLockPID:NotPID1', ...
                    'I cutoff only available for PID 1');
                return;
            end
            
            cmd = sprintf('%s:ICUT %.6f', obj.getCommandBase(), frequency);
            obj.parent.write(cmd);
        end
        
        function freq = getICutoff(obj)
            % Get integral cutoff frequency (PID 1 only)
            
            if obj.pidNumber ~= 1
                freq = [];
                return;
            end
            
            cmd = sprintf('%s:ICUT?', obj.getCommandBase());
            freq = obj.parent.queryNumeric(cmd);
        end
        
        function setSetpoint(obj, setpoint)
            % Set controller setpoint
            %
            % Parameters:
            %   setpoint - Setpoint value
            
            cmd = sprintf('%s:SETP %.6f', obj.getCommandBase(), setpoint);
            obj.parent.write(cmd);
        end
        
        function setpoint = getSetpoint(obj)
            % Get controller setpoint
            cmd = sprintf('%s:SETP?', obj.getCommandBase());
            setpoint = obj.parent.queryNumeric(cmd);
        end
        
        function setSign(obj, sign)
            % Set controller polarity
            %
            % Parameters:
            %   sign - 'POS' or 'NEG'
            
            sign = upper(sign);
            if ~ismember(sign, obj.ValidSigns)
                error('DigiLockPID:InvalidSign', ...
                    'Sign must be POS or NEG');
            end
            
            cmd = sprintf('%s:SIGN %s', obj.getCommandBase(), sign);
            obj.parent.write(cmd);
        end
        
        function sign = getSign(obj)
            % Get controller polarity
            cmd = sprintf('%s:SIGN?', obj.getCommandBase());
            sign = obj.parent.query(cmd);
        end
        
        function setSlope(obj, slope)
            % Set locking slope direction
            %
            % Parameters:
            %   slope - 'POS' or 'NEG'
            
            slope = upper(slope);
            if ~ismember(slope, obj.ValidSlopes)
                error('DigiLockPID:InvalidSlope', ...
                    'Slope must be POS or NEG');
            end
            
            cmd = sprintf('%s:SLOP %s', obj.getCommandBase(), slope);
            obj.parent.write(cmd);
        end
        
        function slope = getSlope(obj)
            % Get locking slope direction
            cmd = sprintf('%s:SLOP?', obj.getCommandBase());
            slope = obj.parent.query(cmd);
        end
        
        function setLimits(obj, minVal, maxVal)
            % Set output limits
            %
            % Parameters:
            %   minVal - Minimum output value (V)
            %   maxVal - Maximum output value (V)
            
            cmd = sprintf('%s:LIM:MIN %.6f', obj.getCommandBase(), minVal);
            obj.parent.write(cmd);
            
            cmd = sprintf('%s:LIM:MAX %.6f', obj.getCommandBase(), maxVal);
            obj.parent.write(cmd);
            
            cmd = sprintf('%s:LIM:STAT ON', obj.getCommandBase());
            obj.parent.write(cmd);
        end
        
        function disableLimits(obj)
            % Disable output limits
            cmd = sprintf('%s:LIM:STAT OFF', obj.getCommandBase());
            obj.parent.write(cmd);
        end
        
        function limits = getLimits(obj)
            % Get output limits
            cmd = sprintf('%s:LIM:MIN?', obj.getCommandBase());
            limits.min = obj.parent.queryNumeric(cmd);
            
            cmd = sprintf('%s:LIM:MAX?', obj.getCommandBase());
            limits.max = obj.parent.queryNumeric(cmd);
            
            cmd = sprintf('%s:LIM:STAT?', obj.getCommandBase());
            response = obj.parent.query(cmd);
            limits.enabled = strcmpi(response, 'ON') || strcmpi(response, '1');
        end
        
        function lock(obj)
            % Engage PID controller (start locking)
            cmd = sprintf('%s:LOCK ON', obj.getCommandBase());
            obj.parent.write(cmd);
        end
        
        function unlock(obj)
            % Disengage PID controller (stop locking)
            cmd = sprintf('%s:LOCK OFF', obj.getCommandBase());
            obj.parent.write(cmd);
        end
        
        function status = getLockStatus(obj)
            % Get lock status
            cmd = sprintf('%s:LOCK?', obj.getCommandBase());
            response = obj.parent.query(cmd);
            status = strcmpi(response, 'ON') || strcmpi(response, '1');
        end
        
        function hold(obj, enable)
            % Set hold state
            %
            % Parameters:
            %   enable - true to hold, false to release
            
            if enable
                state = 'ON';
            else
                state = 'OFF';
            end
            
            cmd = sprintf('%s:HOLD %s', obj.getCommandBase(), state);
            obj.parent.write(cmd);
        end
        
        function status = getHoldStatus(obj)
            % Get hold status
            cmd = sprintf('%s:HOLD?', obj.getCommandBase());
            response = obj.parent.query(cmd);
            status = strcmpi(response, 'ON') || strcmpi(response, '1');
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