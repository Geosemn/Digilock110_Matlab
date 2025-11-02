classdef DigiLock110 < handle
    % DigiLock110 - MATLAB interface for Toptica DigiLock 110
    % 
    % CORRECTED VERSION with proper RCI TCP/IP communication
    %
    % Usage:
    %   dl = DigiLock110('192.168.1.100', 60001);
    %   dl.connect();
    %   dl.pid1.setGain(5);
    %   dl.disconnect();
    
    properties (Access = public)
        % Sub-modules
        scan        % Scan generator module
        pid1        % PID Controller 1
        pid2        % PID Controller 2
        lockin      % Lock-In module
        pdh         % Pound-Drever-Hall module
        autolock    % AutoLock module
        offset      % Offset adjustment
        system      % System configuration
        scope       % Oscilloscope display
        spectrum    % Spectrum analyzer
    end
    
    properties (Access = private)
        tcpClient   % TCP client object
        host        % IP address
        port        % Port number
        connected   % Connection status
        timeout     % Communication timeout (seconds)
        verbose     % Verbose output flag
    end
    
    methods
        function obj = DigiLock110(host, port, varargin)
            % Constructor
            % 
            % Parameters:
            %   host - IP address of DigiLock 110 (string)
            %   port - Port number (use DUI port, typically 60001)
            %   varargin - Optional parameters:
            %              'Timeout', value (default: 5 seconds)
            %              'Verbose', true/false (default: false)
            
            if nargin < 2 || isempty(port)
                port = 60001; % Default DUI port
            end
            
            obj.host = host;
            obj.port = port;
            obj.connected = false;
            obj.timeout = 5;
            obj.verbose = false;
            
            % Parse optional arguments
            p = inputParser;
            addParameter(p, 'Timeout', 5, @isnumeric);
            addParameter(p, 'Verbose', false, @islogical);
            parse(p, varargin{:});
            
            obj.timeout = p.Results.Timeout;
            obj.verbose = p.Results.Verbose;
            
            % Initialize sub-modules
            obj.scan = DigiLockScan(obj);
            obj.pid1 = DigiLockPID(obj, 1);
            obj.pid2 = DigiLockPID(obj, 2);
            obj.lockin = DigiLockLockIn(obj);
            obj.pdh = DigiLockPDH(obj);
            obj.autolock = DigiLockAutoLock(obj);
            obj.offset = DigiLockOffset(obj);
            obj.system = DigiLockSystem(obj);
            obj.scope = DigiLockScope(obj);
            obj.spectrum = DigiLockSpectrum(obj);
        end
        
        function connect(obj)
            % Establish TCP connection to DigiLock 110
            
            try
                if obj.verbose
                    fprintf('Connecting to DigiLock 110 at %s:%d...\n', ...
                        obj.host, obj.port);
                end
                
                obj.tcpClient = tcpclient(obj.host, obj.port, ...
                    'Timeout', obj.timeout);
                
                obj.connected = true;
                
                if obj.verbose
                    fprintf('Connected successfully.\n');
                end
                
                % Wait and clear welcome message
                pause(0.3);
                if obj.tcpClient.NumBytesAvailable > 0
                    read(obj.tcpClient, obj.tcpClient.NumBytesAvailable, 'uint8');
                end
                
                if obj.verbose
                    fprintf('RCI ready.\n');
                end
                
            catch ME
                error('DigiLock110:ConnectionFailed', ...
                    'Failed to connect: %s', ME.message);
            end
        end
        
        function disconnect(obj)
            % Close TCP connection
            
            if obj.connected && ~isempty(obj.tcpClient)
                if obj.verbose
                    fprintf('Disconnecting from DigiLock 110...\n');
                end
                
                clear obj.tcpClient;
                obj.connected = false;
                
                if obj.verbose
                    fprintf('Disconnected.\n');
                end
            end
        end
        
        function write(obj, command)
            % Send command to DigiLock 110
            %
            % Parameters:
            %   command - Command string
            
            if ~obj.connected
                error('DigiLock110:NotConnected', ...
                    'Not connected to device');
            end
            
            try
                if obj.verbose
                    fprintf('>> %s\n', command);
                end
                
                % Send with explicit CR/LF
                write(obj.tcpClient, uint8([command char(13) char(10)]));
                pause(0.05);
                
            catch ME
                error('DigiLock110:WriteFailed', ...
                    'Failed to write: %s', ME.message);
            end
        end
        
        function response = query(obj, command)
            % Send query and receive response
            %
            % Parameters:
            %   command - Query string
            %
            % Returns:
            %   response - Response string
            
            if ~obj.connected
                error('DigiLock110:NotConnected', ...
                    'Not connected to device');
            end
            
            try
                if obj.verbose
                    fprintf('>> %s\n', command);
                end
                
                % Send query with explicit CR/LF
                write(obj.tcpClient, uint8([command char(13) char(10)]));
                
                % Wait for response
                pause(0.3);
                
                if obj.tcpClient.NumBytesAvailable > 0
                    % Read all available bytes
                    raw = read(obj.tcpClient, obj.tcpClient.NumBytesAvailable, 'uint8');
                    response_text = char(raw);
                    
                    % Split by lines
                    lines = splitlines(string(response_text));
                    
                    % Find the response line (contains '=')
                    response = '';
                    for i = 1:length(lines)
                        line = char(lines(i));
                        if contains(line, '=')
                            % Parse "command=value" format
                            parts = split(line, '=');
                            if length(parts) >= 2
                                response = strtrim(parts{2});
                                break;
                            end
                        end
                    end
                    
                    if obj.verbose
                        fprintf('<< %s\n', response);
                    end
                else
                    response = '';
                    if obj.verbose
                        fprintf('<< (no response)\n');
                    end
                end
                
            catch ME
                error('DigiLock110:QueryFailed', ...
                    'Failed to query: %s', ME.message);
            end
        end
        
        function value = queryNumeric(obj, command)
    % Send query and receive numeric response (handles unit suffixes)
    
    response = obj.query(command);
    
    if isempty(response)
        error('DigiLock110:InvalidResponse', ...
            'Received empty response for: %s', command);
    end
    
    % Handle unit suffixes (m=milli, k=kilo, M=mega, etc.)
    response = strtrim(response);
    
    % Check for unit suffix
    if ~isempty(response) && isnan(str2double(response))
        lastChar = response(end);
        numPart = response(1:end-1);
        
        switch lastChar
            case 'm'  % milli (10^-3)
                value = str2double(numPart) * 1e-3;
            case 'u'  % micro (10^-6)
                value = str2double(numPart) * 1e-6;
            case 'n'  % nano (10^-9)
                value = str2double(numPart) * 1e-9;
            case 'k'  % kilo (10^3)
                value = str2double(numPart) * 1e3;
            case 'M'  % mega (10^6)
                value = str2double(numPart) * 1e6;
            case 'G'  % giga (10^9)
                value = str2double(numPart) * 1e9;
            otherwise
                value = str2double(response);
        end
    else
        value = str2double(response);
    end
    
    if isnan(value)
        error('DigiLock110:InvalidResponse', ...
            'Received non-numeric response: %s', response);
    end
end
        
        function reset(obj)
            % Reset device to default state (if supported)
            % Note: RCI may not support *RST
            obj.write('program:exit=false');
            pause(1);
        end
        
        function status = isConnected(obj)
            % Check connection status
            status = obj.connected;
        end
        
        function delete(obj)
            % Destructor - clean up connection
            if obj.connected
                obj.disconnect();
            end
        end
    end
end
