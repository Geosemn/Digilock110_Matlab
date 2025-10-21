classdef DigiLock110 < handle
    % DigiLock110 - MATLAB interface for Toptica DigiLock 110
    % 
    % This class provides remote control of the Toptica DigiLock 110
    % Feedback Controlyzer via TCP/IP connection.
    %
    % Usage:
    %   dl = DigiLock110('192.168.1.100', 5000);
    %   dl.connect();
    %   dl.scan.setFrequency(10); % 10 Hz scan
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
            %   port - Port number (default: 5000)
            %   varargin - Optional parameters:
            %              'Timeout', value (default: 5 seconds)
            %              'Verbose', true/false (default: false)
            
            if nargin < 2 || isempty(port)
                port = 5000; % Default port
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
                
                % Query identification
                idn = obj.query('*IDN?');
                if obj.verbose
                    fprintf('Device: %s\n', idn);
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
                
                writeline(obj.tcpClient, command);
                
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
                obj.write(command);
                response = readline(obj.tcpClient);
                response = char(response);
                
                if obj.verbose
                    fprintf('<< %s\n', response);
                end
                
            catch ME
                error('DigiLock110:QueryFailed', ...
                    'Failed to query: %s', ME.message);
            end
        end
        
        function value = queryNumeric(obj, command)
            % Send query and receive numeric response
            %
            % Parameters:
            %   command - Query string
            %
            % Returns:
            %   value - Numeric value
            
            response = obj.query(command);
            value = str2double(response);
            
            if isnan(value)
                error('DigiLock110:InvalidResponse', ...
                    'Received non-numeric response: %s', response);
            end
        end
        
        function reset(obj)
            % Reset device to default state
            obj.write('*RST');
            pause(1); % Wait for reset
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