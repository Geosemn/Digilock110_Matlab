% ========================================================================
% DigiLockOffset - Offset adjustment module
% ========================================================================
classdef DigiLockOffset < handle
    properties (Access = private)
        parent
    end
    
    properties (Constant)
        ValidOutputs = {'MainOut', 'AuxOut', 'SC110', 'AIO1', 'AIO2'};
    end
    
    methods
        function obj = DigiLockOffset(parent)
            obj.parent = parent;
        end
        
        function setOffset(obj, output, value)
            % Set DC offset for output channel
            output = upper(strrep(output, ' ', ''));
            if ~ismember(output, upper(obj.ValidOutputs))
                error('Invalid output channel');
            end
            obj.parent.write(sprintf('OFFS:%s %.6f', output, value));
        end
        
        function value = getOffset(obj, output)
            % Get DC offset for output channel
            output = upper(strrep(output, ' ', ''));
            value = obj.parent.queryNumeric(sprintf('OFFS:%s?', output));
        end
    end
end

