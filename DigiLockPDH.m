classdef DigiLockPDH < handle
    % DigiLockPDH - Pound-Drever-Hall modulation/demodulation module
    % CORRECTED VERSION with proper RCI command syntax
    
    properties (Access = private)
        parent
    end
    
    properties (Constant)
        ValidInputs = {'main in', 'aux in'};
        ValidOutputs = {'main out', 'aux out', 'sc110 out', 'aio1 out', 'aio2 out'};
        ValidFrequencies = {'25MHz', '12.5MHz', '6.25MHz', '3.13MHz', '1.56MHz'};
    end
    
    methods
        function obj = DigiLockPDH(parent)
            obj.parent = parent;
        end
        
        function setFrequency(obj, frequency)
            % RCI Command: pdh:modulation:frequency set=12.5MHz
            % Can also use numeric value
            if isnumeric(frequency)
                freq_MHz = frequency / 1e6;
                freqStr = sprintf('%.2fMHz', freq_MHz);
            else
                freqStr = frequency;
            end
            obj.parent.write(sprintf('pdh:modulation:frequency set=%s', freqStr));
        end
        
        function freq = getFrequency(obj)
            % RCI Command: pdh:modulation:frequency set?
            response = obj.parent.query('pdh:modulation:frequency set?');
            % Parse MHz string to Hz
            if contains(response, 'MHz')
                freq = str2double(strrep(response, 'MHz', '')) * 1e6;
            else
                freq = str2double(response);
            end
        end
        
        function setAmplitude(obj, amplitude)
            % RCI Command: pdh:modulation:amplitude=0.1
            if amplitude < 0
                error('DigiLockPDH:InvalidAmplitude', 'Amplitude must be non-negative');
            end
            obj.parent.write(sprintf('pdh:modulation:amplitude=%.6f', amplitude));
        end
        
        function amp = getAmplitude(obj)
            % RCI Command: pdh:modulation:amplitude?
            amp = obj.parent.queryNumeric('pdh:modulation:amplitude?');
        end
        
        function setOutput(obj, output)
            % RCI Command: pdh:modulation:output=main out
            output = lower(output);
            if strcmpi(output, 'mainout'), output = 'main out'; end
            if strcmpi(output, 'sc110'), output = 'sc110 out'; end
            obj.parent.write(sprintf('pdh:modulation:output=%s', output));
        end
        
        function output = getOutput(obj)
            % RCI Command: pdh:modulation:output?
            output = obj.parent.query('pdh:modulation:output?');
        end
        
        function setInput(obj, input)
            % RCI Command: pdh:input=main in
            input = lower(input);
            if strcmpi(input, 'mainin'), input = 'main in'; end
            obj.parent.write(sprintf('pdh:input=%s', input));
        end
        
        function input = getInput(obj)
            % RCI Command: pdh:input?
            input = obj.parent.query('pdh:input?');
        end
        
        function setPhase(obj, phase)
            % RCI Command: pdh:phase shift=0
            obj.parent.write(sprintf('pdh:phase shift=%.6f', phase));
        end
        
        function phase = getPhase(obj)
            % RCI Command: pdh:phase shift?
            phase = obj.parent.queryNumeric('pdh:phase shift?');
        end
        
        function setOffset(obj, offset)
            % RCI Command: pdh:offset=0
            obj.parent.write(sprintf('pdh:offset=%.6f', offset));
        end
        
        function offset = getOffset(obj)
            % RCI Command: pdh:offset?
            offset = obj.parent.queryNumeric('pdh:offset?');
        end
        
        function start(obj)
            % RCI Command: pdh:modulation:enable=true
            obj.parent.write('pdh:modulation:enable=true');
        end
        
        function stop(obj)
            % RCI Command: pdh:modulation:enable=false
            obj.parent.write('pdh:modulation:enable=false');
        end
        
        function status = getStatus(obj)
            % RCI Command: pdh:modulation:enable?
            response = obj.parent.query('pdh:modulation:enable?');
            status = strcmpi(response, 'true') || strcmpi(response, '1');
        end
        
        function adjustPhase(obj)
            % RCI Command: pdh:phase adjust=true
            obj.parent.write('pdh:phase adjust=true');
            pause(5);
        end
        
        function configure(obj, varargin)
            p = inputParser;
            addParameter(p, 'Frequency', [], @(x) isnumeric(x) || ischar(x));
            addParameter(p, 'Amplitude', [], @isnumeric);
            addParameter(p, 'Output', '', @ischar);
            addParameter(p, 'Input', '', @ischar);
            addParameter(p, 'Phase', [], @isnumeric);
            addParameter(p, 'Offset', [], @isnumeric);
            addParameter(p, 'Start', false, @islogical);
            parse(p, varargin{:});
            
            if ~isempty(p.Results.Frequency), obj.setFrequency(p.Results.Frequency); end
            if ~isempty(p.Results.Amplitude), obj.setAmplitude(p.Results.Amplitude); end
            if ~isempty(p.Results.Output), obj.setOutput(p.Results.Output); end
            if ~isempty(p.Results.Input), obj.setInput(p.Results.Input); end
            if ~isempty(p.Results.Phase), obj.setPhase(p.Results.Phase); end
            if ~isempty(p.Results.Offset), obj.setOffset(p.Results.Offset); end
            if p.Results.Start, obj.start(); end
        end
        
        function params = getAll(obj)
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
