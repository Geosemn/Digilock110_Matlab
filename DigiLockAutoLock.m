% ========================================================================
% DigiLockAutoLock - AutoLock module
% ========================================================================
classdef DigiLockAutoLock < handle
    properties (Access = private)
        parent
    end
    
    methods
        function obj = DigiLockAutoLock(parent)
            obj.parent = parent;
        end
        
        function enable(obj, state)
            % Enable/disable AutoLock
            if state
                obj.parent.write('AUTO:STAT ON');
            else
                obj.parent.write('AUTO:STAT OFF');
            end
        end
        
        function setInput(obj, input)
            % Set common input for AutoLock controllers
            obj.parent.write(sprintf('AUTO:INP %s', upper(input)));
        end
        
        function input = getInput(obj)
            input = obj.parent.query('AUTO:INP?');
        end
        
        function setSetpoint(obj, value)
            % Set common setpoint
            obj.parent.write(sprintf('AUTO:SETP %.6f', value));
        end
        
        function value = getSetpoint(obj)
            value = obj.parent.queryNumeric('AUTO:SETP?');
        end
        
        function selectControllers(obj, pid1, pid2)
            % Select which PID controllers to use in AutoLock
            % pid1, pid2: true/false
            obj.parent.write(sprintf('AUTO:PID1 %d', pid1));
            obj.parent.write(sprintf('AUTO:PID2 %d', pid2));
        end
        
        function lockToSlope(obj)
            % Initiate lock to slope (side-of-fringe)
            obj.parent.write('AUTO:LOCK:SLOPE');
        end
        
        function lockToExtremum(obj)
            % Initiate lock to extremum (top-of-fringe with FM)
            obj.parent.write('AUTO:LOCK:EXTR');
        end
        
        function unlock(obj)
            % Release lock
            obj.parent.write('AUTO:UNLOCK');
        end
    end
end
