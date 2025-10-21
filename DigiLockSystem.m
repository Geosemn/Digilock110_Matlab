
% ========================================================================
% DigiLockSystem - System configuration module
% ========================================================================
classdef DigiLockSystem < handle
    properties (Access = private)
        parent
    end
    
    methods
        function obj = DigiLockSystem(parent)
            obj.parent = parent;
        end
        
        function setInputOffset(obj, value)
            % Set Main input offset
            obj.parent.write(sprintf('SYST:INP:OFFS %.6f', value));
        end
        
        function value = getInputOffset(obj)
            value = obj.parent.queryNumeric('SYST:INP:OFFS?');
        end
        
        function setInputGain(obj, value)
            % Set Main input analog gain
            obj.parent.write(sprintf('SYST:INP:GAIN %.6f', value));
        end
        
        function value = getInputGain(obj)
            value = obj.parent.queryNumeric('SYST:INP:GAIN?');
        end
        
        function setInvert(obj, enable)
            % Invert input signal
            if enable
                obj.parent.write('SYST:INP:INV ON');
            else
                obj.parent.write('SYST:INP:INV OFF');
            end
        end
        
        function status = getInvert(obj)
            response = obj.parent.query('SYST:INP:INV?');
            status = strcmpi(response, 'ON') || strcmpi(response, '1');
        end
        
        function setLowPassFilter(obj, frequency, order)
            % Configure low-pass filter
            obj.parent.write(sprintf('SYST:FILT:LP:FREQ %.6f', frequency));
            obj.parent.write(sprintf('SYST:FILT:LP:ORD %d', order));
            obj.parent.write('SYST:FILT:LP:STAT ON');
        end
        
        function disableLowPassFilter(obj)
            obj.parent.write('SYST:FILT:LP:STAT OFF');
        end
        
        function setHighPassFilter(obj, frequency, order)
            % Configure high-pass filter
            obj.parent.write(sprintf('SYST:FILT:HP:FREQ %.6f', frequency));
            obj.parent.write(sprintf('SYST:FILT:HP:ORD %d', order));
            obj.parent.write('SYST:FILT:HP:STAT ON');
        end
        
        function disableHighPassFilter(obj)
            obj.parent.write('SYST:FILT:HP:STAT OFF');
        end
    end
end
