classdef DigiLockScan < handle
    % DigiLockScan - Scan generator module for DigiLock 110
    %
    % This class controls the scan waveform generation for scanning
    % the laser wavelength.
    %
    % Properties settable:
    %   - Signal type (sine, triangle, square, sawtooth)
    %   - Frequency (Hz)
    %   - Amplitude (V peak-to-peak)
    %   - Output channel
    %
    % Usage:
    %   dl.scan.setType('triangle');
    %   dl.scan.setFrequency(10);
    %   dl.scan.setAmplitude(5.0);
    %   dl.scan.setOutput('SC110');
    %   dl.scan.start();
    
    properties (Access = private)
        parent  % Parent DigiLock110 object
    end
    
    properties (Constant)
        ValidTypes = {'sine', 'triangle', 'square', 'sawtooth'};
        ValidOutputs = {'Main', 'Aux', 'SC110', 'AIO1', 'AIO2'};
    end
    
    methods
        function obj = DigiLockScan(parent)
            % Constructor
            obj.parent = parent;
        end
        
        function setType(obj, signalType)
            % Set scan waveform type
            %
            % Parameters:
            %   signalType - 'sine', 'triangle', 'square', or 'sawtooth'
            
            signalType = lower(signalType);
            if ~ismember(signalType, obj.ValidTypes)
                error('DigiLockScan:InvalidType', ...
                    'Invalid signal type. Must be: %s', ...
                    strjoin(obj.ValidTypes, ', '));
            end
            
            obj.parent.write(sprintf('SCAN:TYPE %s', upper(signalType)));
        end
        
        function type = getType(obj)
            % Get current scan waveform type
            type = obj.parent.query('SCAN:TYPE?');
        end
        
        function setFrequency(obj, frequency)
            % Set scan frequency in Hz
            %
            % Parameters:
            %   frequency - Frequency in Hz (positive number)
            
            if frequency <= 0
                error('DigiLockScan:InvalidFrequency', ...
                    'Frequency must be positive');
            end
            
            obj.parent.write(sprintf('SCAN:FREQ %.6f', frequency));
        end
        
        function freq = getFrequency(obj)
            % Get current scan frequency in Hz
            freq = obj.parent.queryNumeric('SCAN:FREQ?');
        end
        
        function setAmplitude(obj, amplitude)
            % Set scan amplitude in Volts (peak-to-peak)
            %
            % Parameters:
            %   amplitude - Amplitude in V (0 to 10 V typical)
            
            if amplitude < 0
                error('DigiLockScan:InvalidAmplitude', ...
                    'Amplitude must be non-negative');
            end
            
            obj.parent.write(sprintf('SCAN:AMPL %.6f', amplitude));
        end
        
        function amp = getAmplitude(obj)
            % Get current scan amplitude in V
            amp = obj.parent.queryNumeric('SCAN:AMPL?');
        end
        
        function setOutput(obj, output)
            % Set output channel for scan signal
            %
            % Parameters:
            %   output - Output channel name
            %            'Main', 'Aux', 'SC110', 'AIO1', 'AIO2'
            
            output = upper(output);
            if ~ismember(output, upper(obj.ValidOutputs))
                error('DigiLockScan:InvalidOutput', ...
                    'Invalid output. Must be: %s', ...
                    strjoin(obj.ValidOutputs, ', '));
            end
            
            obj.parent.write(sprintf('SCAN:OUTP %s', output));
        end
        
        function output = getOutput(obj)
            % Get current output channel
            output = obj.parent.query('SCAN:OUTP?');
        end
        
        function start(obj)
            % Start scan generation
            obj.parent.write('SCAN:STAT ON');
        end
        
        function stop(obj)
            % Stop scan generation
            obj.parent.write('SCAN:STAT OFF');
        end
        
        function status = getStatus(obj)
            % Get scan status (ON/OFF)
            response = obj.parent.query('SCAN:STAT?');
            status = strcmpi(response, 'ON') || strcmpi(response, '1');
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
            %                     'Output', 'SC110', ...
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