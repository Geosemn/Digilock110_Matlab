classdef DigiLockOffset < handle
    % DigiLockOffset - Offset adjustment module
    % CORRECTED VERSION with proper RCI command syntax
    
    properties (Access = private)
        parent
    end
    
    properties (Constant)
        ValidOutputs = {'main out', 'aux out', 'sc110 out', 'aio1 out', 'aio2 out'};
    end
    
    methods
        function obj = DigiLockOffset(parent)
            obj.parent = parent;
        end
        
        function setOffset(obj, output, value)
            % Set DC offset for output channel
            % RCI Commands: offset:output=sc110 out, then offset:value=0
            
            output = lower(output);
            if strcmpi(output, 'sc110'), output = 'sc110 out'; end
            if strcmpi(output, 'main'), output = 'main out'; end
            if strcmpi(output, 'aux'), output = 'aux out'; end
            
            if ~ismember(output, obj.ValidOutputs)
                error('Invalid output channel');
            end
            
            % First set the output channel
            obj.parent.write(sprintf('offset:output=%s', output));
            pause(0.1);
            
            % Then set the value
            obj.parent.write(sprintf('offset:value=%.6f', value));
        end
        
        function value = getOffset(obj, output)
            % Get DC offset for output channel
            
            output = lower(output);
            if strcmpi(output, 'sc110'), output = 'sc110 out'; end
            
            % First set the output to query
            obj.parent.write(sprintf('offset:output=%s', output));
            pause(0.1);
            
            % Then query the value
            value = obj.parent.queryNumeric('offset:value?');
        end
    end
end
