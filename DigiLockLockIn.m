classdef DigiLockLockIn < handle
    % DigiLockLockIn - Lock-In modulation/demodulation module
    % CORRECTED VERSION with proper RCI command syntax
    
    properties (Access = private)
        parent
    end
    
    properties (Constant)
        ValidInputs = {'main in', 'aux in'};
        ValidOutputs = {'main out', 'aux out', 'sc110 out', 'aio1 out', 'aio2 out'};
    end
    
    methods
        function obj = DigiLockLockIn(parent)
            obj.parent = parent;
        end
        
        function setFrequency(obj, frequency)
            % RCI Command: li:modulation:frequency set=100000
            if frequency <= 0
                error('DigiLockLockIn:InvalidFrequency', 'Frequency must be positive');
            end
            obj.parent.write(sprintf('li:modulation:frequency set=%.6f', frequency));
        end
        
        function freq = getSetFrequency(obj)
            % RCI Command: li:modulation:frequency set?
            freq = obj.parent.queryNumeric('li:modulation:frequency set?');
        end
        
        function freq = getActualFrequency(obj)
            % RCI Command: li:modulation:frequency act?
            freq = obj.parent.queryNumeric('li:modulation:frequency act?');
        end
        
        function setAmplitude(obj, amplitude)
            % RCI Command: li:modulation:amplitude=0.01
            if amplitude < 0
                error('DigiLockLockIn:InvalidAmplitude', 'Amplitude must be non-negative');
            end
            obj.parent.write(sprintf('li:modulation:amplitude=%.6f', amplitude));
        end
        
        function amp = getAmplitude(obj)
            % RCI Command: li:modulation:amplitude?
            amp = obj.parent.queryNumeric('li:modulation:amplitude?');
        end
        
        function setOutput(obj, output)
            % RCI Command: li:modulation:output=main out
            output = lower(output);
            if strcmpi(output, 'mainout'), output = 'main out'; end
            if strcmpi(output, 'sc110'), output = 'sc110 out'; end
            obj.parent.write(sprintf('li:modulation:output=%s', output));
        end
        
        function output = getOutput(obj)
            % RCI Command: li:modulation:output?
            output = obj.parent.query('li:modulation:output?');
        end
        
        function setInput(obj, input)
            % RCI Command: li:input=main in
            input = lower(input);
            if strcmpi(input, 'mainin'), input = 'main in'; end
            obj.parent.write(sprintf('li:input=%s', input));
        end
        
        function input = getInput(obj)
            % RCI Command: li:input?
            input = obj.parent.query('li:input?');
        end
        
        function setPhase(obj, phase)
            % RCI Command: li:phase shift=0
            obj.parent.write(sprintf('li:phase shift=%.6f', phase));
        end
        
        function phase = getPhase(obj)
            % RCI Command: li:phase shift?
            phase = obj.parent.queryNumeric('li:phase shift?');
        end
        
        function setOffset(obj, offset)
            % RCI Command: li:offset=0
            obj.parent.write(sprintf('li:offset=%.6f', offset));
        end
        
        function offset = getOffset(obj)
            % RCI Command: li:offset?
            offset = obj.parent.queryNumeric('li:offset?');
        end
        
        function start(obj)
            % RCI Command: li:modulation:enable=true
            obj.parent.write('li:modulation:enable=true');
        end
        
        function stop(obj)
            % RCI Command: li:modulation:enable=false
            obj.parent.write('li:modulation:enable=false');
        end
        
        function status = getStatus(obj)
            % RCI Command: li:modulation:enable?
            response = obj.parent.query('li:modulation:enable?');
            status = strcmpi(response, 'true') || strcmpi(response, '1');
        end
        
        function adjustPhase(obj)
            % RCI Command: li:phase adjust=true
            obj.parent.write('li:phase adjust=true');
            pause(5);
        end
        
        function configure(obj, varargin)
            p = inputParser;
            addParameter(p, 'Frequency', [], @isnumeric);
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
