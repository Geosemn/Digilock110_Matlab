
% ========================================================================
% DigiLockScope - Oscilloscope display module
% ========================================================================
classdef DigiLockScope < handle
    properties (Access = private)
        parent
    end
    
    methods
        function obj = DigiLockScope(parent)
            obj.parent = parent;
        end
        
        function data = acquire(obj, channel, numPoints)
            % Acquire oscilloscope data
            % channel: 1 or 2
            % numPoints: number of points to acquire
            
            if nargin < 3
                numPoints = 1000;
            end
            
            cmd = sprintf('SCOP:CH%d:DATA? %d', channel, numPoints);
            response = obj.parent.query(cmd);
            
            % Parse response (assuming comma-separated values)
            data = str2num(response); %#ok<ST2NM>
        end
        
        function setChannel(obj, channel, source)
            % Set input source for scope channel
            % channel: 1 or 2
            % source: signal name
            cmd = sprintf('SCOP:CH%d:SOUR %s', channel, upper(source));
            obj.parent.write(cmd);
        end
        
        function setTimebase(obj, timebase)
            % Set timebase in seconds per division
            obj.parent.write(sprintf('SCOP:TIMEB %.6e', timebase));
        end
    end
end
