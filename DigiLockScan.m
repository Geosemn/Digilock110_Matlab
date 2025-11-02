classdef DigiLockScan < handle
    % DigiLockScan - Scan generator module for DigiLock 110
    % CORRECTED VERSION with proper RCI command syntax
    
    properties (Access = private)
        parent  % Parent DigiLock110 object
    end
    
    properties (Constant)
        ValidTypes = {'sine', 'triangle', 'square', 'sawtooth'};
        ValidOutputs = {'main out', 'aux out', 'sc110 out', 'aio1 out', 'aio2 out'};
    end
    
    methods
        function obj = DigiLockScan(parent)
            obj.parent = parent;
        end
        
        function setType(obj, signalType)
            % Set scan waveform type
            % RCI Command: scan:signal type=triangle
            
            signalType = lower(signalType);
            if ~ismember(signalType, obj.ValidTypes)
                error('DigiLockScan:InvalidType', ...
                    'Invalid signal type. Must be: %s', ...
                    strjoin(obj.ValidTypes, ', '));
            end
            
            obj.parent.write(sprintf('scan:signal type=%s', signalType));
        end
        
        function type = getType(obj)
            % Get current scan waveform type
            % RCI Command: scan:signal type?
            type = obj.parent.query('scan:signal type?');
        end
        
        function setFrequency(obj, frequency)
            % Set scan frequency in Hz
            % RCI Command: scan:frequency=10.0
            
            if frequency <= 0
                error('DigiLockScan:InvalidFrequency', ...
                    'Frequency must be positive');
            end
            
            obj.parent.write(sprintf('scan:frequency=%.6f', frequency));
        end
        
        function freq = getFrequency(obj)
            % Get current scan frequency in Hz
            % RCI Command: scan:frequency?
            freq = obj.parent.queryNumeric('scan:frequency?');
        end
        
        function setAmplitude(obj, amplitude)
            % Set scan amplitude in Volts (peak-to-peak)
            % RCI Command: scan:amplitude=5.0
            
            if amplitude < 0
                error('DigiLockScan:InvalidAmplitude', ...
                    'Amplitude must be non-negative');
            end
            
            obj.parent.write(sprintf('scan:amplitude=%.6f', amplitude));
        end
        
        function amp = getAmplitude(obj)
            % Get current scan amplitude in V
            % RCI Command: scan:amplitude?
            amp = obj.parent.queryNumeric('scan:amplitude?');
        end
        
        function setOutput(obj, output)
            % Set output channel for scan signal
            % RCI Command: scan:output=sc110 out
            
            output = lower(output);
            
            % Handle special cases
            if strcmpi(output, 'sc110')
                output = 'sc110 out';
            elseif strcmpi(output, 'main')
                output = 'main out';
            elseif strcmpi(output, 'aux')
                output = 'aux out';
            end
            
            if ~ismember(output, obj.ValidOutputs)
                error('DigiLockScan:InvalidOutput', ...
                    'Invalid output. Must be: %s', ...
                    strjoin(obj.ValidOutputs, ', '));
            end
            
            obj.parent.write(sprintf('scan:output=%s', output));
        end
        
        function output = getOutput(obj)
            % Get current output channel
            % RCI Command: scan:output?
            output = obj.parent.query('scan:output?');
        end
        
        function start(obj)
            % Start scan generation
            % RCI Command: scan:enable=true
            obj.parent.write('scan:enable=true');
        end
        
        function stop(obj)
            % Stop scan generation
            % RCI Command: scan:enable=false
            obj.parent.write('scan:enable=false');
        end
        
        function status = getStatus(obj)
            % Get scan status
            % RCI Command: scan:enable?
            response = obj.parent.query('scan:enable?');
            status = strcmpi(response, 'true') || strcmpi(response, '1');
        end
        
        function configure(obj, varargin)
            % Configure multiple scan parameters at once
            %
            % Parameters (name-value pairs):
            %   'Type' - Signal type
            %   'Frequency' - Frequency in Hz
            %   'Amplitude' - Amplitude in V
            %   'Output' - Output channel
            %   'Start' - true/false to start scan
            %
            % Example:
            %   dl.scan.configure('Type', 'triangle', ...
            %                     'Frequency', 10, ...
            %                     'Amplitude', 5, ...
            %                     'Output', 'sc110 out', ...
            %                     'Start', true);
            
            p = inputParser;
            addParameter(p, 'Type', '', @ischar);
            addParameter(p, 'Frequency', [], @isnumeric);
            addParameter(p, 'Amplitude', [], @isnumeric);
            addParameter(p, 'Output', '', @ischar);
            addParameter(p, 'Start', false, @islogical);
            parse(p, varargin{:});
            
            if ~isempty(p.Results.Type)
                obj.setType(p.Results.Type);
            end
            
            if ~isempty(p.Results.Frequency)
                obj.setFrequency(p.Results.Frequency);
            end
            
            if ~isempty(p.Results.Amplitude)
                obj.setAmplitude(p.Results.Amplitude);
            end
            
            if ~isempty(p.Results.Output)
                obj.setOutput(p.Results.Output);
            end
            
            if p.Results.Start
                obj.start();
            end
        end
        
        function params = getAll(obj)
            % Get all scan parameters as a struct
            params.type = obj.getType();
            params.frequency = obj.getFrequency();
            params.amplitude = obj.getAmplitude();
            params.output = obj.getOutput();
            params.status = obj.getStatus();
        end
    end
end
