
% ========================================================================
% DigiLockSpectrum - Spectrum analyzer module
% ========================================================================
classdef DigiLockSpectrum < handle
    properties (Access = private)
        parent
    end
    
    methods
        function obj = DigiLockSpectrum(parent)
            obj.parent = parent;
        end
        
        function data = acquire(obj, channel)
            % Acquire spectrum data (FFT)
            % channel: 1 or 2
            
            cmd = sprintf('SPEC:CH%d:DATA?', channel);
            response = obj.parent.query(cmd);
            
            % Parse response
            data = str2num(response); %#ok<ST2NM>
        end
        
        function setChannel(obj, channel, source)
            % Set input source for spectrum channel
            cmd = sprintf('SPEC:CH%d:SOUR %s', channel, upper(source));
            obj.parent.write(cmd);
        end
        
        function setSpan(obj, span)
            % Set frequency span in Hz
            obj.parent.write(sprintf('SPEC:SPAN %.6f', span));
        end
        
        function span = getSpan(obj)
            span = obj.parent.queryNumeric('SPEC:SPAN?');
        end
    end
end