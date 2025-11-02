classdef DigiLockSpectrum < handle
    % DigiLockSpectrum - Spectrum analyzer module
    % CORRECTED VERSION with proper RCI command syntax
    
    properties (Access = private)
        parent
    end
    
    methods
        function obj = DigiLockSpectrum(parent)
            obj.parent = parent;
        end
        
        function data = acquire(obj, channel)
            % Acquire spectrum data (FFT)
            % RCI Command: spectrum:graph?
            
            response = obj.parent.query('spectrum:graph?');
            
            if isempty(response)
                data = [];
                return;
            end
            
            try
                response = strrep(response, '[', '');
                response = strrep(response, ']', '');
                data_matrix = str2num(response); %#ok<ST2NM>
                
                if ~isempty(data_matrix) && size(data_matrix, 2) >= channel
                    data = data_matrix(:, channel);
                else
                    data = [];
                end
            catch
                data = [];
            end
        end
        
        function setChannel(obj, channel, source)
            % RCI Command: spectrum:ch1:channel=main in
            source = lower(source);
            obj.parent.write(sprintf('spectrum:ch%d:channel=%s', channel, source));
        end
        
        function setSpan(obj, span)
            % RCI Command: spectrum:frequency scale=10kHz
            % Can use string or numeric (Hz)
            if isnumeric(span)
                if span >= 1e3
                    spanStr = sprintf('%.1fkHz', span/1e3);
                else
                    spanStr = sprintf('%.1fHz', span);
                end
            else
                spanStr = span;
            end
            obj.parent.write(sprintf('spectrum:frequency scale=%s', spanStr));
        end
        
        function span = getSpan(obj)
            % RCI Command: spectrum:frequency scale?
            response = obj.parent.query('spectrum:frequency scale?');
            % Parse response (may contain units)
            if contains(response, 'kHz')
                span = str2double(strrep(response, 'kHz', '')) * 1e3;
            elseif contains(response, 'MHz')
                span = str2double(strrep(response, 'MHz', '')) * 1e6;
            else
                span = str2double(strrep(response, 'Hz', ''));
            end
        end
    end
end
