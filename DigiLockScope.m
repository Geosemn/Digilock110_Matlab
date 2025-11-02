% classdef DigiLockScope < handle
%     % DigiLockScope - Oscilloscope display module
%     % CORRECTED VERSION with proper RCI command syntax
% 
%     properties (Access = private)
%         parent
%     end
% 
%     methods
%         function obj = DigiLockScope(parent)
%             obj.parent = parent;
%         end
% 
%         function data = acquire(obj, channel, numPoints)
%             % Acquire oscilloscope data
%             % RCI Command: scope:graph? returns 2D array
%             %
%             % Parameters:
%             %   channel - 1 or 2
%             %   numPoints - number of points (default: 1000)
%             %
%             % Returns:
%             %   data - Column vector of voltage values
% 
%             if nargin < 3
%                 numPoints = 1000;
%             end
% 
%             % Get the full scope graph
%             response = obj.parent.query('scope:graph?');
% 
%             if isempty(response)
%                 data = zeros(numPoints, 1);
%                 return;
%             end
% 
%             % Parse the response - typically array format
%             % Response format varies, try to parse as numbers
%             try
%                 % Remove brackets if present
%                 response = strrep(response, '[', '');
%                 response = strrep(response, ']', '');
% 
%                 % Parse as matrix
%                 data_matrix = str2num(response); %#ok<ST2NM>
% 
%                 if isempty(data_matrix)
%                     data = zeros(numPoints, 1);
%                     return;
%                 end
% 
%                 % Extract requested channel
%                 if size(data_matrix, 2) >= channel
%                     data = data_matrix(:, channel);
%                 else
%                     data = data_matrix(:, 1);
%                 end
% 
%                 % Limit to requested points
%                 if length(data) > numPoints
%                     data = data(1:numPoints);
%                 elseif length(data) < numPoints
%                     % Pad with zeros if needed
%                     data = [data; zeros(numPoints - length(data), 1)];
%                 end
% 
%             catch
%                 % If parsing fails, return zeros
%                 data = zeros(numPoints, 1);
%             end
%         end
% 
%         function setChannel(obj, channel, source)
%             % Set input source for scope channel
%             % RCI Command: scope:ch1:channel=main in
%             %
%             % Parameters:
%             %   channel - 1 or 2
%             %   source - signal name (e.g., 'main in', 'aux in')
% 
%             source = lower(source);
% 
%             % Handle special cases
%             if strcmpi(source, 'mainin')
%                 source = 'main in';
%             elseif strcmpi(source, 'mainout')
%                 source = 'main out';
%             elseif strcmpi(source, 'auxin')
%                 source = 'aux in';
%             elseif strcmpi(source, 'auxout')
%                 source = 'aux out';
%             elseif strcmpi(source, 'sc110')
%                 source = 'sc110 out';
%             elseif strcmpi(source, 'liout')
%                 source = 'li out';
%             elseif strcmpi(source, 'pdhout')
%                 source = 'pdh out';
%             end
% 
%             cmd = sprintf('scope:ch%d:channel=%s', channel, source);
%             obj.parent.write(cmd);
%         end
% 
%         function setTimebase(obj, timebase)
%             % Set timebase
%             % RCI Command: scope:timescale=100ms
%             %
%             % Parameters:
%             %   timebase - Timebase as string (e.g., '100ms', '1s')
% 
%             obj.parent.write(sprintf('scope:timescale=%s', timebase));
%         end
% 
%         function enableXY(obj, enable)
%             % Enable/disable XY mode
%             % RCI Command: scope:xymode=true
% 
%             if enable
%                 obj.parent.write('scope:xymode=true');
%             else
%                 obj.parent.write('scope:xymode=false');
%             end
%         end
% 
%         function setXChannel(obj, source)
%             % Set X-axis channel for XY mode
%             % RCI Command: scope:chx:channel=scan output
% 
%             source = lower(source);
%             obj.parent.write(sprintf('scope:chx:channel=%s', source));
%         end
%     end
% end


classdef DigiLockScope < handle
    % DigiLockScope - Oscilloscope display module
    % CORRECTED VERSION - Fixed data parsing
    
    properties (Access = private)
        parent
    end
    
    methods
        function obj = DigiLockScope(parent)
            obj.parent = parent;
        end
        
        function data = acquire(obj, channel, numPoints)
            % Acquire oscilloscope data
            % RCI returns tab-separated scientific notation
            
            if nargin < 3
                numPoints = 1000;
            end
            
            % Query the scope graph (may need multiple queries)
            response = obj.parent.query('scope:graph?');
            
            if isempty(response) || strcmpi(response, 'main in') || strcmpi(response, 'aux in')
                % First query sometimes returns channel name, try again
                pause(0.1);
                response = obj.parent.query('scope:graph?');
            end
            
            if isempty(response)
                data = zeros(numPoints, 1);
                return;
            end
            
            try
                % Split by tabs (data is tab-separated)
                values_str = strsplit(response, '\t');
                
                % Convert to numbers (handles scientific notation)
                values = [];
                for i = 1:length(values_str)
                    val = str2double(values_str{i});
                    if ~isnan(val)
                        values(end+1) = val;
                    end
                end
                
                if isempty(values)
                    data = zeros(numPoints, 1);
                    return;
                end
                
                % Data format: CH1_1, CH2_1, CH1_2, CH2_2, ...
                % Separate into channels
                ch1_data = values(1:2:end);  % Odd indices
                ch2_data = values(2:2:end);  % Even indices
                
                % Select requested channel
                if channel == 1
                    data = ch1_data(:);
                else
                    data = ch2_data(:);
                end
                
                % Pad or truncate to requested size
                if length(data) < numPoints
                    data = [data; zeros(numPoints - length(data), 1)];
                elseif length(data) > numPoints
                    data = data(1:numPoints);
                end
                
            catch ME
                warning('Scope data parsing failed: %s', ME.message);
                data = zeros(numPoints, 1);
            end
        end
        
        function setChannel(obj, channel, source)
            % Set input source for scope channel
            % RCI Command: scope:ch1:channel=main in
            
            source = lower(source);
            
            % Handle special cases
            if strcmpi(source, 'mainin'), source = 'main in'; end
            if strcmpi(source, 'mainout'), source = 'main out'; end
            if strcmpi(source, 'auxin'), source = 'aux in'; end
            if strcmpi(source, 'auxout'), source = 'aux out'; end
            if strcmpi(source, 'sc110'), source = 'sc110 out'; end
            if strcmpi(source, 'liout'), source = 'li out'; end
            if strcmpi(source, 'pdhout'), source = 'pdh out'; end
            if strcmpi(source, 'aio1out'), source = 'aio1 out'; end
            if strcmpi(source, 'aio2out'), source = 'aio2 out'; end
            
            cmd = sprintf('scope:ch%d:channel=%s', channel, source);
            obj.parent.write(cmd);
        end
        
        function setTimebase(obj, timebase)
            % Set timebase
            % RCI Command: scope:timescale=100ms
            obj.parent.write(sprintf('scope:timescale=%s', timebase));
        end
        
        function enableXY(obj, enable)
            % Enable/disable XY mode
            if enable
                obj.parent.write('scope:xymode=true');
            else
                obj.parent.write('scope:xymode=false');
            end
        end
        
        function setXChannel(obj, source)
            % Set X-axis channel for XY mode
            source = lower(source);
            obj.parent.write(sprintf('scope:chx:channel=%s', source));
        end
    end
end