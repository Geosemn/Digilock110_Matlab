%% Simple DigiLock 110: Set PID, Lock, and Monitor MainIn/MainOut
% CORRECTED VERSION with proper RCI command syntax
%
% This version uses the correct lowercase commands with proper syntax
% based on the DigiLock 110 RCI Manual

% Connect to DigiLock 110
dl = DigiLock110('192.168.1.100', 5000, 'Verbose', true);
dl.connect();

% Configure scope channels to display MainIn and MainOut
% CORRECTED: Use lowercase with spaces: 'main in' not 'MainIn'
dl.scope.setChannel(1, 'main in');
dl.scope.setChannel(2, 'main out');

% Configure PID 1 with input/output routing
% CORRECTED: Use lowercase with spaces
dl.pid1.setInput('main in');    % Sends: pid1:input=main in
dl.pid1.setOutput('main out');  % Sends: pid1:output=main out

% Set PID parameters
% CORRECTED: Now uses proper command names
dl.pid1.setP(1.0);          % Sends: pid1:proportional=1.0
dl.pid1.setI(0.3);          % Sends: pid1:integral=0.3
dl.pid1.setD(0.05);         % Sends: pid1:differential=0.05
dl.pid1.setSetpoint(0);     % Sends: pid1:setpoint=0

% Engage lock
% CORRECTED: Now sends pid1:lock:enable=true
dl.pid1.lock();

% Wait for system to settle
pause(2);

% Check lock status
% CORRECTED: Now queries pid1:lock:state?
lock_status = dl.pid1.getLockStatus();
fprintf('Lock Status: %d (1=locked, 0=unlocked)\n', lock_status);

% Acquire MainIn and MainOut values
main_in_data = dl.scope.acquire(1, 1000);
main_out_data = dl.scope.acquire(2, 1000);

% Display values
fprintf('MainIn average: %.6f V\n', mean(main_in_data));
fprintf('MainOut average: %.6f V\n', mean(main_out_data));
fprintf('MainIn current: %.6f V\n', main_in_data(end));
fprintf('MainOut current: %.6f V\n', main_out_data(end));

% Cleanup
dl.disconnect();
clear dl;

fprintf('\n=== Lock Test Complete ===\n');
