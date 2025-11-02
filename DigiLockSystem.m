classdef DigiLockSystem < handle
    % DigiLockSystem - System configuration module
    % CORRECTED VERSION with proper RCI command syntax
    
    properties (Access = private)
        parent
    end
    
    methods
        function obj = DigiLockSystem(parent)
            obj.parent = parent;
        end
        
        function setInputOffset(obj, value)
            % RCI Command: main in:input offset=0
            obj.parent.write(sprintf('main in:input offset=%.6f', value));
        end
        
        function value = getInputOffset(obj)
            % RCI Command: main in:input offset?
            value = obj.parent.queryNumeric('main in:input offset?');
        end
        
        function setInputGain(obj, value)
            % RCI Command: main in:gain=1
            obj.parent.write(sprintf('main in:gain=%d', value));
        end
        
        function value = getInputGain(obj)
            % RCI Command: main in:gain?
            value = obj.parent.queryNumeric('main in:gain?');
        end
        
        function setInvert(obj, enable)
            % RCI Command: main in:invert=true
            if enable
                obj.parent.write('main in:invert=true');
            else
                obj.parent.write('main in:invert=false');
            end
        end
        
        function status = getInvert(obj)
            % RCI Command: main in:invert?
            response = obj.parent.query('main in:invert?');
            status = strcmpi(response, 'true') || strcmpi(response, '1');
        end
        
        function setLowPassFilter(obj, frequency, order)
            % RCI Commands: main in:low pass:frequency, :order, :bypass
            obj.parent.write(sprintf('main in:low pass:frequency=%.6f', frequency));
            obj.parent.write(sprintf('main in:low pass:order=%d', order));
            obj.parent.write('main in:low pass:bypass=false');
        end
        
        function disableLowPassFilter(obj)
            % RCI Command: main in:low pass:bypass=true
            obj.parent.write('main in:low pass:bypass=true');
        end
        
        function setHighPassFilter(obj, frequency, order)
            % RCI Commands: main in:high pass:frequency, :order, :bypass
            obj.parent.write(sprintf('main in:high pass:frequency=%.6f', frequency));
            obj.parent.write(sprintf('main in:high pass:order=%d', order));
            obj.parent.write('main in:high pass:bypass=false');
        end
        
        function disableHighPassFilter(obj)
            % RCI Command: main in:high pass:bypass=true
            obj.parent.write('main in:high pass:bypass=true');
        end
    end
end
