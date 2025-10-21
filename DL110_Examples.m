% ========================================================================
% DigiLock 110 MATLAB Control Examples
% ========================================================================
% This script demonstrates various usage scenarios for controlling
% the Toptica DigiLock 110 via TCP/IP
%
% Before running:
% 1. Ensure DigiLock 110 is connected to network
% 2. Note the IP address and port number from the DigiLock Module Server
% 3. Update the connection parameters below
% ========================================================================

%% Example 1: Basic Connection and Scan Setup
% Connect to DigiLock 110
dl = DigiLock110('192.168.1.100', 5000, 'Verbose', true);
dl.connect();

% Configure basic scan for finding resonance
dl.scan.configure('Type', 'triangle', ...
                  'Frequency', 10, ...        % 10 Hz
                  'Amplitude', 5.0, ...       % 5 V pp
                  'Output', 'SC110', ...
                  'Start', true);

% Set offset for SC110 output
dl.offset.setOffset('SC110', 0);

% Wait and observe scan
pause(5);

% Stop scan
dl.scan.stop();

%% Example 2: Side-of-Fringe Locking (Simple PID)
% Configure system input
dl.system.setInputOffset(0);
dl.system.setInputGain(1);

% Configure PID 1 for fast feedback (current modulation)
dl.pid1.setInput('MainIn');
dl.pid1.setOutput('MainOut');
dl.pid1.setGain(5);
dl.pid1.setP(1.0);
dl.pid1.setI(0.3);
dl.pid1.setD(0.05);
dl.pid1.setICutoff(100);  % 100 Hz
dl.pid1.setSign('POS');
dl.pid1.setSlope('POS');
dl.pid1.setSetpoint(0);

% Configure PID 2 for slow feedback (piezo)
dl.pid2.setInput('MainIn');
dl.pid2.setOutput('SC110');
dl.pid2.setGain(3);
dl.pid2.setP(1.0);
dl.pid2.setI(0.5);
dl.pid2.setD(0.02);
dl.pid2.setSign('POS');
dl.pid2.setSlope('POS');
dl.pid2.setSetpoint(0);

% Set output limits (optional)
dl.pid2.setLimits(-5, 5);  % +/- 5V range

% Engage locks
dl.pid2.lock();  % Start with slow loop
pause(1);
dl.pid1.lock();  % Then add fast loop

% Monitor lock status
fprintf('PID 1 locked: %d\n', dl.pid1.getLockStatus());
fprintf('PID 2 locked: %d\n', dl.pid2.getLockStatus());

%% Example 3: Top-of-Fringe Lock with Lock-In
% Configure Lock-In modulation
dl.lockin.configure('Frequency', 100e3, ...    % 100 kHz
                    'Amplitude', 0.01, ...     % 10 mV pp
                    'Output', 'MainOut', ...
                    'Input', 'MainIn', ...
                    'Phase', 0);

% Start modulation and scan to find resonance
dl.lockin.start();
dl.scan.configure('Type', 'triangle', ...
                  'Frequency', 10, ...
                  'Amplitude', 5.0, ...
                  'Output', 'SC110', ...
                  'Start', true);

pause(2);  % Observe signal

% Adjust phase for optimal error signal
% Manual adjustment:
dl.lockin.setPhase(90);  % Try different values

% Or use automatic adjustment:
% dl.lockin.adjustPhase();

% Stop scan and configure AutoLock
dl.scan.stop();

% Set up AutoLock for Lock-In
dl.autolock.enable(true);
dl.autolock.setInput('LIOut');
dl.autolock.setSetpoint(0);
dl.autolock.selectControllers(true, true);  % Use both PIDs

% PIDs should already be configured (see Example 2)
% Update input to LIOut
dl.pid1.setInput('LIOut');
dl.pid2.setInput('LIOut');

% Initiate lock to extremum (peak or valley)
dl.autolock.lockToExtremum();

% Monitor
pause(5);

%% Example 4: Pound-Drever-Hall Lock to Cavity
% Configure PDH modulation
dl.pdh.configure('Frequency', 12.5e6, ...    % 12.5 MHz
                 'Amplitude', 0.1, ...       % 100 mV pp
                 'Output', 'MainOut', ...
                 'Input', 'MainIn', ...
                 'Phase', 0, ...
                 'Start', true);

% Scan to find cavity resonance
dl.scan.configure('Type', 'triangle', ...
                  'Frequency', 10, ...
                  'Amplitude', 3.0, ...
                  'Output', 'SC110', ...
                  'Start', true);

pause(2);

% Optimize phase
% Manual:
dl.pdh.setPhase(45);  % Adjust as needed

% Or automatic:
% dl.pdh.adjustPhase();

% Set up AutoLock for PDH
dl.scan.stop();
dl.autolock.setInput('PDHOut');
dl.pid1.setInput('PDHOut');
dl.pid2.setInput('PDHOut');

% Initiate lock
dl.autolock.lockToExtremum();

%% Example 5: Data Acquisition and Monitoring
% Acquire scope data
ch1_data = dl.scope.acquire(1, 1000);
ch2_data = dl.scope.acquire(2, 1000);

% Plot
figure;
subplot(2,1,1);
plot(ch1_data);
title('Scope Channel 1');
xlabel('Sample');
ylabel('Voltage (V)');
grid on;

subplot(2,1,2);
plot(ch2_data);
title('Scope Channel 2');
xlabel('Sample');
ylabel('Voltage (V)');
grid on;

% Acquire spectrum data
spec_data = dl.spectrum.acquire(1);

figure;
plot(spec_data);
title('Spectrum Channel 1');
xlabel('Frequency Bin');
ylabel('Amplitude');
grid on;
set(gca, 'YScale', 'log');

%% Example 6: Parameter Sweeping and Optimization
% Sweep PID parameters to find optimal settings
gains = [1, 2, 5, 10, 20];
rms_errors = zeros(size(gains));

for i = 1:length(gains)
    % Set gain
    dl.pid1.setGain(gains(i));
    
    % Wait for settling
    pause(2);
    
    % Acquire error signal
    error_data = dl.scope.acquire(1, 1000);
    
    % Calculate RMS
    rms_errors(i) = rms(error_data - mean(error_data));
    
    fprintf('Gain: %.1f, RMS Error: %.6f\n', gains(i), rms_errors(i));
end

% Plot optimization results
figure;
plot(gains, rms_errors, 'o-', 'LineWidth', 2);
xlabel('Gain');
ylabel('RMS Error (V)');
title('PID Gain Optimization');
grid on;

% Find optimal gain
[min_error, idx] = min(rms_errors);
optimal_gain = gains(idx);
fprintf('Optimal gain: %.1f (RMS: %.6f)\n', optimal_gain, min_error);

% Set to optimal
dl.pid1.setGain(optimal_gain);

%% Example 7: Monitoring and Relock
% Continuous monitoring loop
fprintf('Monitoring lock status...\n');
fprintf('Press Ctrl+C to stop\n\n');

try
    while true
        % Check lock status
        pid1_locked = dl.pid1.getLockStatus();
        pid2_locked = dl.pid2.getLockStatus();
        
        % Get PID outputs (if available)
        % output1 = dl.pid1.getOutput();
        
        fprintf('Time: %s | PID1: %d | PID2: %d\n', ...
                datestr(now, 'HH:MM:SS'), pid1_locked, pid2_locked);
        
        % If lost lock, attempt relock
        if ~pid1_locked || ~pid2_locked
            fprintf('Lock lost! Attempting relock...\n');
            
            % Unlock all
            dl.pid1.unlock();
            dl.pid2.unlock();
            
            % Restart scan
            dl.scan.start();
            pause(2);
            
            % Relock
            dl.autolock.lockToExtremum();
            pause(1);
        end
        
        pause(1);  % Check every second
    end
catch ME
    fprintf('Monitoring stopped: %s\n', ME.message);
end

%% Example 8: Getting All Parameters
% Retrieve complete system state
scan_params = dl.scan.getAll();
pid1_params = dl.pid1.getAll();
pid2_params = dl.pid2.getAll();
lockin_params = dl.lockin.getAll();
pdh_params = dl.pdh.getAll();

% Display
fprintf('\n=== System Configuration ===\n');
fprintf('Scan:\n');
disp(scan_params);

fprintf('PID 1:\n');
disp(pid1_params);

fprintf('PID 2:\n');
disp(pid2_params);

fprintf('Lock-In:\n');
disp(lockin_params);

fprintf('PDH:\n');
disp(pdh_params);

%% Cleanup
% Always disconnect when done
dl.disconnect();
clear dl;

fprintf('\n=== Examples Complete ===\n');