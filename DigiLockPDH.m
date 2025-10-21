classdef DigiLockPDH < handle
    % DigiLockPDH - Pound-Drever-Hall modulation/demodulation module
    %
    % Generates error signals for cavity locking using high-frequency
    % modulation (MHz range).
    %
    % Usage:
    %   dl.pdh.setFrequency(12.5e6);  % 12.5 MHz
    %   dl.pdh.setAmplitude(0.1);     % 100 mV pp
    %   dl.pdh.setOutput('MainOut');
    %   dl.pdh.setInput('MainIn');
    %   dl.pdh.setPhase(0);
    %   dl.pdh.start();
    
    properties (Access = private)
        parent  % Parent DigiLock110 object
    end
    
    properties (Constant)
        ValidInputs = {'MainIn', 'AuxIn'};
        ValidOutputs = {'MainOut', 'AuxOut', 'SC110', 'AIO1', 'AIO2'};
        % Available frequencies: 25, 12.5, 6.25, 3.13, 1.56 MHz
        ValidFrequencies = [25e6, 12.5e6, 6.25e6, 3.13e6, 1.56e6];
    end
    
    methods
        function obj = DigiLockPDH(parent)
            % Constructor
            obj.parent = parent;
        end
        
        function setFrequency(obj, frequency)
            % Set modulation frequency in Hz
            %
            % Parameters:
            %   frequency - Modulation frequency in Hz
            %               Must be one of: 25, 12.5, 6.25, 3.13, 1.56 MHz
            
            if frequency <= 0
                error('DigiLockPDH:InvalidFrequency', ...
                    'Frequency must be positive');
            end
            
            % Find closest valid frequency
            [~, idx] = min(abs(obj.ValidFrequencies - frequency));
            actualFreq = obj.ValidFrequencies(idx);
            
            if abs(frequency - actualFreq) > 0.1e6
                warning('DigiLockPDH:FrequencyAdjusted', ...
                    'Requested %.2f MHz, set to nearest valid: %.2f MHz', ...
                    frequency/1e6, actualFreq/1e6);
            end
            
            obj.parent.write(sprintf('PDH:FREQ %.6f', frequency));
        end
        
        function freq = getFrequency(obj)
            % Get modulation frequency
            freq = obj.parent.queryNumeric('PDH:FREQ?');
        end
        
        function setAmplitude(obj, amplitude)
            % Set modulation amplitude in Volts (peak-to-peak)
            %
            % Parameters:
            %   amplitude - Amplitude in V
            
            if amplitude < 0
                error('DigiLockPDH:InvalidAmplitude', ...
                    'Amplitude must be non-negative');
            end
            
            obj.parent.write(sprintf('PDH:AMPL %.6f', amplitude));
        end
        
        function amp = getAmplitude(obj)
            % Get modulation amplitude
            amp = obj.parent.queryNumeric('PDH:AMPL?');
        end
        
        function setOutput(obj, output)
            % Set output channel for modulation signal
            %
            % Parameters:
            %   output - Output channel name
            
            output = upper(strrep(output, ' ', ''));
            if ~ismember(output, upper(obj.ValidOutputs))
                error('DigiLockPDH:InvalidOutput', ...
                    'Invalid output. Must be: %s', ...
                    strjoin(obj.ValidOutputs, ', '));
            end
            
            obj.parent.write(sprintf('PDH:OUTP %s', output));
        end
        
        function output = getOutput(obj)
            % Get current output channel
            output = obj.parent.query('PDH:OUTP?');
        end
        
        function setInput(obj, input)
            % Set input channel for demodulation
            %
            % Parameters:
            %   input - Input channel name
            
            input = upper(strrep(input, ' ', ''));
            if ~ismember(input, upper(obj.ValidInputs))
                error('DigiLockPDH:InvalidInput', ...
                    'Invalid input. Must be: %s', ...
                    strjoin(obj.ValidInputs, ', '));
            end
            
            obj.parent.write(sprintf('PDH:INP %s', input));
        end
        
        function input = getInput(obj)
            % Get current input channel
            input = obj.parent.query('PDH:INP?');
        end
        
        function setPhase(obj, phase)
            % Set demodulation phase in degrees
            %
            % Parameters:
            %   phase - Phase shift in degrees (0-360)
            
            obj.parent.write(sprintf('PDH:PHAS %.6f', phase));
        end
        
        function phase = getPhase(obj)
            % Get demodulation phase
            phase = obj.parent.queryNumeric('PDH:PHAS?');
        end
        
        function setOffset(obj, offset)
            % Set output offset
            %
            % Parameters:
            %   offset - Offset value
            
            obj.parent.write(sprintf('PDH:OFFS %.6f', offset));
        end
        
        function offset = getOffset(obj)
            % Get output offset
            offset = obj.parent.queryNumeric('PDH:OFFS?');
        end
        
        function start(obj)
            % Start modulation
            obj.parent.write('PDH:STAT ON');
        end
        
        function stop(obj)
            % Stop modulation
            obj.parent.write('PDH:STAT OFF');
        end
        
        function status = getStatus(obj)
            % Get modulation status
            response = obj.parent.query('PDH:STAT?');
            status = strcmpi(response, 'ON') || strcmpi(response, '1');
        end
        
        function adjustPhase(obj)
            % Automatically adjust phase for optimal error signal
            % This may take several seconds
            
            obj.parent.write('PDH:PHAS:ADJ');
            
            % Wait for adjustment to complete
            pause(5);
        end
        
        function configure(obj, varargin)
            % Configure multiple PDH parameters at once
            %
            % Parameters (name-value pairs):
            %   'Frequency' - Modulation frequency in Hz
            %   'Amplitude' - Amplitude in V
            %   'Output' - Output channel
            %   'Input' - Input channel
            %   'Phase' - Phase in degrees
            %   'Offset' - Offset value
            %   'Start' - true/false to start modulation
            %
            % Example:
            %   dl.pdh.configure('Frequency', 12.5e6, ...
            %                    'Amplitude', 0.1, ...
            %                    'Output', 'MainOut', ...
            %                    'Input', 'MainIn', ...
            %                    'Start', true);
            
            p = inputParser;
            addParameter(p, 'Frequency', [], @isnumeric);
            addParameter(p, 'Amplitude', [], @isnumeric);
            addParameter(p, 'Output', '', @ischar);
            addParameter(p, 'Input', '', @ischar);
            addParameter(p, 'Phase', [], @isnumeric);
            addParameter(p, 'Offset', [], @isnumeric);
            addParameter(p, 'Start', false, @islogical);
            parse(p, varargin{:});
            
            if ~isempty(p.Results.Frequency)
                obj.setFrequency(p.Results.Frequency);
            end
            
            if ~isempty(p.Results.Amplitude)
                obj.setAmplitude(p.Results.Amplitude);
            end
            
            if ~isempty(p.Results.Output)
                obj.setOutput(p.Results.Output);
            end
            
            if ~isempty(p.Results.Input)
                obj.setInput(p.Results.Input);
            end
            
            if ~isempty(p.Results.Phase)
                obj.setPhase(p.Results.Phase);
            end
            
            if ~isempty(p.Results.Offset)
                obj.setOffset(p.Results.Offset);
            end
            
            if p.Results.Start
                obj.start();
            end
        end
        
        function params = getAll(obj)
            % Get all PDH parameters as a struct
            params.frequency = obj.getFrequency();
            params.amplitude = obj.getAmplitude();
            params.output = obj.getOutput();
            params.input = obj.getInput();
            params.phase = obj.getPhase();
            params.offset = obj.getOffset();
            params.status = obj.getStatus();
        end
    end
end