classdef DigiLockLockIn < handle
    % DigiLockLockIn - Lock-In modulation/demodulation module
    %
    % Generates error signals for top-of-fringe locking using
    % frequency modulation and demodulation.
    %
    % Usage:
    %   dl.lockin.setFrequency(100e3);  % 100 kHz
    %   dl.lockin.setAmplitude(0.01);   % 10 mV pp
    %   dl.lockin.setOutput('MainOut');
    %   dl.lockin.setInput('MainIn');
    %   dl.lockin.setPhase(0);
    %   dl.lockin.start();
    
    properties (Access = private)
        parent  % Parent DigiLock110 object
    end
    
    properties (Constant)
        ValidInputs = {'MainIn', 'AuxIn'};
        ValidOutputs = {'MainOut', 'AuxOut', 'SC110', 'AIO1', 'AIO2'};
    end
    
    methods
        function obj = DigiLockLockIn(parent)
            % Constructor
            obj.parent = parent;
        end
        
        function setFrequency(obj, frequency)
            % Set modulation frequency in Hz
            %
            % Parameters:
            %   frequency - Modulation frequency in Hz
            %
            % Note: Only discrete frequencies are available
            %       (even fractions of 781.25 kHz)
            
            if frequency <= 0
                error('DigiLockLockIn:InvalidFrequency', ...
                    'Frequency must be positive');
            end
            
            obj.parent.write(sprintf('LI:FREQ:SET %.6f', frequency));
        end
        
        function freq = getSetFrequency(obj)
            % Get requested modulation frequency
            freq = obj.parent.queryNumeric('LI:FREQ:SET?');
        end
        
        function freq = getActualFrequency(obj)
            % Get actual modulation frequency
            % (closest available discrete frequency)
            freq = obj.parent.queryNumeric('LI:FREQ:ACT?');
        end
        
        function setAmplitude(obj, amplitude)
            % Set modulation amplitude in Volts (peak-to-peak)
            %
            % Parameters:
            %   amplitude - Amplitude in V
            
            if amplitude < 0
                error('DigiLockLockIn:InvalidAmplitude', ...
                    'Amplitude must be non-negative');
            end
            
            obj.parent.write(sprintf('LI:AMPL %.6f', amplitude));
        end
        
        function amp = getAmplitude(obj)
            % Get modulation amplitude
            amp = obj.parent.queryNumeric('LI:AMPL?');
        end
        
        function setOutput(obj, output)
            % Set output channel for modulation signal
            %
            % Parameters:
            %   output - Output channel name
            
            output = upper(strrep(output, ' ', ''));
            if ~ismember(output, upper(obj.ValidOutputs))
                error('DigiLockLockIn:InvalidOutput', ...
                    'Invalid output. Must be: %s', ...
                    strjoin(obj.ValidOutputs, ', '));
            end
            
            obj.parent.write(sprintf('LI:OUTP %s', output));
        end
        
        function output = getOutput(obj)
            % Get current output channel
            output = obj.parent.query('LI:OUTP?');
        end
        
        function setInput(obj, input)
            % Set input channel for demodulation
            %
            % Parameters:
            %   input - Input channel name
            
            input = upper(strrep(input, ' ', ''));
            if ~ismember(input, upper(obj.ValidInputs))
                error('DigiLockLockIn:InvalidInput', ...
                    'Invalid input. Must be: %s', ...
                    strjoin(obj.ValidInputs, ', '));
            end
            
            obj.parent.write(sprintf('LI:INP %s', input));
        end
        
        function input = getInput(obj)
            % Get current input channel
            input = obj.parent.query('LI:INP?');
        end
        
        function setPhase(obj, phase)
            % Set demodulation phase in degrees
            %
            % Parameters:
            %   phase - Phase shift in degrees (0-360)
            
            obj.parent.write(sprintf('LI:PHAS %.6f', phase));
        end
        
        function phase = getPhase(obj)
            % Get demodulation phase
            phase = obj.parent.queryNumeric('LI:PHAS?');
        end
        
        function setOffset(obj, offset)
            % Set output offset
            %
            % Parameters:
            %   offset - Offset value
            
            obj.parent.write(sprintf('LI:OFFS %.6f', offset));
        end
        
        function offset = getOffset(obj)
            % Get output offset
            offset = obj.parent.queryNumeric('LI:OFFS?');
        end
        
        function start(obj)
            % Start modulation
            obj.parent.write('LI:STAT ON');
        end
        
        function stop(obj)
            % Stop modulation
            obj.parent.write('LI:STAT OFF');
        end
        
        function status = getStatus(obj)
            % Get modulation status
            response = obj.parent.query('LI:STAT?');
            status = strcmpi(response, 'ON') || strcmpi(response, '1');
        end
        
        function adjustPhase(obj)
            % Automatically adjust phase for optimal error signal
            % This may take several seconds
            
            obj.parent.write('LI:PHAS:ADJ');
            
            % Wait for adjustment to complete
            % Poll status or wait fixed time
            pause(5);
        end
        
        function configure(obj, varargin)
            % Configure multiple Lock-In parameters at once
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
            %   dl.lockin.configure('Frequency', 100e3, ...
            %                       'Amplitude', 0.01, ...
            %                       'Output', 'MainOut', ...
            %                       'Input', 'MainIn', ...
            %                       'Start', true);
            
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
            % Get all Lock-In parameters as a struct
            params.frequencySet = obj.getSetFrequency();
            params.frequencyActual = obj.getActualFrequency();
            params.amplitude = obj.getAmplitude();
            params.output = obj.getOutput();
            params.input = obj.getInput();
            params.phase = obj.getPhase();
            params.offset = obj.getOffset();
            params.status = obj.getStatus();
        end
    end
end