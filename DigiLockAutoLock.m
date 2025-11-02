classdef DigiLockAutoLock < handle
    % DigiLockAutoLock - AutoLock module
    % CORRECTED VERSION with proper RCI command syntax
    
    properties (Access = private)
        parent
    end
    
    methods
        function obj = DigiLockAutoLock(parent)
            obj.parent = parent;
        end
        
        function enable(obj, state)
            % RCI Command: autolock:enable=true
            if state
                obj.parent.write('autolock:enable=true');
            else
                obj.parent.write('autolock:enable=false');
            end
        end
        
        function setInput(obj, input)
            % RCI Command: autolock:input=li out
            input = lower(input);
            if strcmpi(input, 'liout'), input = 'li out'; end
            if strcmpi(input, 'pdhout'), input = 'pdh out'; end
            obj.parent.write(sprintf('autolock:input=%s', input));
        end
        
        function input = getInput(obj)
            % RCI Command: autolock:input?
            input = obj.parent.query('autolock:input?');
        end
        
        function setSetpoint(obj, value)
            % RCI Command: autolock:setpoint=0
            obj.parent.write(sprintf('autolock:setpoint=%.6f', value));
        end
        
        function value = getSetpoint(obj)
            % RCI Command: autolock:setpoint?
            value = obj.parent.queryNumeric('autolock:setpoint?');
        end
        
        function selectControllers(obj, pid1, pid2)
            % RCI Commands: autolock:controller:pid1, :pid2
            if pid1
                obj.parent.write('autolock:controller:pid1=true');
            else
                obj.parent.write('autolock:controller:pid1=false');
            end
            
            if pid2
                obj.parent.write('autolock:controller:pid2=true');
            else
                obj.parent.write('autolock:controller:pid2=false');
            end
        end
        
        function lockToSlope(obj)
            % RCI Command: autolock:lock:strategy=slope
            obj.parent.write('autolock:lock:strategy=slope');
            obj.parent.write('autolock:lock:enable=true');
        end
        
        function lockToExtremum(obj)
            % RCI Command: autolock:lock:strategy=extremum
            obj.parent.write('autolock:lock:strategy=extremum');
            obj.parent.write('autolock:lock:enable=true');
        end
        
        function unlock(obj)
            % RCI Command: autolock:lock:enable=false
            obj.parent.write('autolock:lock:enable=false');
        end
    end
end
