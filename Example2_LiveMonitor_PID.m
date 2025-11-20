%% DigiLock 110 PID Test with Live Plotting
% Enhanced version with real-time graphs using DIRECT QUERIES
% WORKING VERSION - Uses scope mean/rms queries instead of graph data

%% Setup and Connection
clear all;
close all;

% Connection parameters
IP_ADDRESS = '10.129.216.210';
PORT = 60001;  % DUI port

dl = DigiLock110(IP_ADDRESS, PORT, 'Verbose', true);
dl.connect();

% Configure scope channels (CORRECTED: lowercase with spaces)
fprintf('Configuring scope channels...\n');
dl.scope.setChannel(1, 'main in');
dl.scope.setChannel(2, 'aio1 out');

%% Configure PID Parameters
fprintf('Configuring PID parameters...\n');

% All PID parameters including Gain
dl.pid1.setInput('main in');
dl.pid1.setOutput('aio1 out');
dl.pid1.setGain(1.0);            % Overall gain
dl.pid1.setP(1000000.0);         % Proportional gain
dl.pid1.setI(150.0);             % Integral gain
dl.pid1.setD(8742.0);            % Derivative gain
dl.pid1.setSetpoint(0.018);      % Target setpoint in Volts

% Engage lock
fprintf('Engaging lock...\n');
dl.pid1.lock();
pause(1);

fprintf('\nPID locked. Starting live monitoring...\n');
fprintf('Close the figure window or press Ctrl+C to stop\n\n');

%% Create Figure with Multiple Subplots
fig = figure('Name', 'DigiLock 110 Live Monitor', ...
             'NumberTitle', 'off', ...
             'Position', [100, 100, 1400, 800]);

% Create subplots
subplot(2,3,1); % MainIn mean vs time
h_main_in = animatedline('Color', 'b', 'LineWidth', 2);
title('MainIn Mean vs Time');
xlabel('Time (s)');
ylabel('Voltage (V)');
grid on;
hold on;
plot([0 100], [0.018 0.018], 'r--', 'LineWidth', 2);

subplot(2,3,2); % AIO1 Out mean vs time
h_aio1_out = animatedline('Color', 'r', 'LineWidth', 2);
title('AIO1 Out Mean vs Time');
xlabel('Time (s)');
ylabel('Voltage (V)');
grid on;

subplot(2,3,3); % Error vs time
h_error = animatedline('Color', 'k', 'LineWidth', 2);
title('Error (MainIn - Setpoint) vs Time');
xlabel('Time (s)');
ylabel('Error (V)');
grid on;
hold on;
plot([0 100], [0 0], 'r--', 'LineWidth', 1);

subplot(2,3,4); % MainIn RMS vs time
h_main_in_rms = animatedline('Color', [0 0.5 1], 'LineWidth', 2);
title('MainIn RMS vs Time');
xlabel('Time (s)');
ylabel('RMS (V)');
grid on;

subplot(2,3,5); % AIO1 Out RMS vs time
h_aio1_out_rms = animatedline('Color', [1 0.5 0], 'LineWidth', 2);
title('AIO1 Out RMS vs Time');
xlabel('Time (s)');
ylabel('RMS (V)');
grid on;

subplot(2,3,6); % Statistics display
ax_stats = subplot(2,3,6);
axis off;

%% Monitoring Loop
startTime = tic;
iteration = 0;

% Storage for time series
max_points = 200;
time_history = [];
main_in_history = [];
aio1_out_history = [];
error_history = [];
main_in_rms_history = [];
aio1_out_rms_history = [];

% PID parameters for display
PID_GAIN = 1.0;
PID_P = 1000000.0;
PID_I = 150.0;
PID_D = 8742.0;
SETPOINT = 0.018; % use any

try
    while ishandle(fig)
        iteration = iteration + 1;
        current_time = toc(startTime);
        
        % Check lock status
        try
            lock_status = dl.pid1.getLockStatus();
        catch
            lock_status = false;
        end
        
        % Query scope values directly using mean and RMS
        try
            main_in_mean = dl.queryNumeric('scope:ch1:mean?');
            main_in_rms = dl.queryNumeric('scope:ch1:rms?');
            aio1_out_mean = dl.queryNumeric('scope:ch2:mean?');
            aio1_out_rms = dl.queryNumeric('scope:ch2:rms?');
        catch ME
            fprintf('Warning: Query failed: %s\n', ME.message);
            pause(0.5);
            continue;
        end
        
        % Calculate error
        error_val = main_in_mean - SETPOINT;
        
        % Store history
        time_history(end+1) = current_time;
        main_in_history(end+1) = main_in_mean;
        aio1_out_history(end+1) = aio1_out_mean;
        error_history(end+1) = error_val;
        main_in_rms_history(end+1) = main_in_rms;
        aio1_out_rms_history(end+1) = aio1_out_rms;
        
        % Keep only last max_points
        if length(time_history) > max_points
            time_history = time_history(end-max_points+1:end);
            main_in_history = main_in_history(end-max_points+1:end);
            aio1_out_history = aio1_out_history(end-max_points+1:end);
            error_history = error_history(end-max_points+1:end);
            main_in_rms_history = main_in_rms_history(end-max_points+1:end);
            aio1_out_rms_history = aio1_out_rms_history(end-max_points+1:end);
        end
        
        % Update all plots
        subplot(2,3,1);
        clearpoints(h_main_in);
        addpoints(h_main_in, time_history, main_in_history);
        xlim([max(0, current_time-60), current_time+1]);
        if ~isempty(main_in_history)
            ylim([min(main_in_history)-0.001, max(main_in_history)+0.001]);
        end
        
        subplot(2,3,2);
        clearpoints(h_aio1_out);
        addpoints(h_aio1_out, time_history, aio1_out_history);
        xlim([max(0, current_time-60), current_time+1]);
        
        subplot(2,3,3);
        clearpoints(h_error);
        addpoints(h_error, time_history, error_history);
        xlim([max(0, current_time-60), current_time+1]);
        if ~isempty(error_history)
            ylim([min(error_history)-0.0005, max(error_history)+0.0005]);
        end
        
        subplot(2,3,4);
        clearpoints(h_main_in_rms);
        addpoints(h_main_in_rms, time_history, main_in_rms_history);
        xlim([max(0, current_time-60), current_time+1]);
        
        subplot(2,3,5);
        clearpoints(h_aio1_out_rms);
        addpoints(h_aio1_out_rms, time_history, aio1_out_rms_history);
        xlim([max(0, current_time-60), current_time+1]);
        
        % Update statistics display (subplot 6)
        subplot(2,3,6);
        cla;
        axis off;
        
        stats_text = {
            '\bf\fontsize{12}PID Parameters:',
            sprintf('\\fontsize{10}Gain:       %.1f', PID_GAIN),
            sprintf('P:          %.0f', PID_P),
            sprintf('I:          %.1f', PID_I),
            sprintf('D:          %.1f', PID_D),
            sprintf('Setpoint:   %.6f V', SETPOINT),
            '',
            '\bf\fontsize{12}Current Status:',
            sprintf('\\fontsize{10}Lock:       %s', iif(lock_status, '\color{green}LOCKED', '\color{red}UNLOCKED')),
            '',
            '\bf\fontsize{12}Current Values:',
            sprintf('\\fontsize{10}\\color{black}MainIn:     %.6f V', main_in_mean),
            sprintf('AIO1 Out:   %.6f V', aio1_out_mean),
            sprintf('Error:      %+.6f V', error_val),
            '',
            '\bf\fontsize{12}Signal Quality:',
            sprintf('\\fontsize{10}MainIn RMS:  %.6f V', main_in_rms),
            sprintf('AIO1 RMS:    %.6f V', aio1_out_rms),
            '',
            sprintf('\\fontsize{10}Runtime:    %.1f s', current_time),
            sprintf('Updates:    %d', iteration)
        };
        
        text(0.05, 0.95, stats_text, ...
            'VerticalAlignment', 'top', ...
            'FontName', 'FixedWidth', ...
            'FontSize', 9, ...
            'Interpreter', 'tex');
        
        % Console output (reduced frequency) for live verification 
        if mod(iteration, 5) == 0
            fprintf('%.1fs\t| %d    | %.6f\t| %.6f\t| %+.6f\t| %.6f\n', ...
                current_time, lock_status, main_in_mean, aio1_out_mean, ...
                error_val, main_in_rms);
        end
        
        drawnow limitrate;
        pause(0.2);
    end
catch ME
    fprintf('\nMonitoring stopped: %s\n', ME.message);
    fprintf('Stack trace:\n');
    disp(ME.stack);
end

%% Cleanup
fprintf('\nCleaning up...\n');
if ishandle(fig)
    close(fig);
end

try
    dl.pid1.unlock();
    fprintf('PID unlocked\n');
catch
    fprintf('Could not unlock PID\n');
end

try
    dl.disconnect();
    fprintf('Disconnected\n');
catch
    fprintf('Could not disconnect\n');
end

clear dl;
fprintf('\n=== Monitoring Complete ===\n');

%% Helper Function
function out = iif(condition, trueVal, falseVal)
    if condition
        out = trueVal;
    else
        out = falseVal;
    end
end
