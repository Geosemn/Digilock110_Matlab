%% DigiLock 110 PID Test with Live Plotting
% Enhanced version with real-time graphs and full PID parameter control

%% Setup and Connection
dl = DigiLock110('10.129.216.210', 60001, 'Verbose', true);
dl.connect();

% Configure scope channels (CORRECTED: lowercase with spaces)
dl.scope.setChannel(1, 'main in');
dl.scope.setChannel(2, 'aio1 out');

%% Configure PID Parameters
% All PID parameters including Gain
dl.pid1.setInput('main in');
dl.pid1.setOutput('aio1 out');
dl.pid1.setGain(1.0);            % Overall gain
dl.pid1.setP(1000000.0);         % Proportional gain
dl.pid1.setI(150.0);             % Integral gain
dl.pid1.setD(8742.0);            % Derivative gain
dl.pid1.setSetpoint(0.018);      % Target setpoint

% Engage lock
dl.pid1.lock();
fprintf('PID locked. Starting live monitoring...\n');
fprintf('Close the figure window or press Ctrl+C to stop\n\n');

%% Create Figure with Multiple Subplots
fig = figure('Name', 'DigiLock 110 Live Monitor', ...
             'NumberTitle', 'off', ...
             'Position', [100, 100, 1200, 700]);

% Create subplots
subplot(2,2,1); % MainIn trace
h_in = plot(nan, nan, 'b-', 'LineWidth', 1.5);
title('MainIn Signal (Live)');
xlabel('Sample');
ylabel('Voltage (V)');
grid on;
hold on;
h_in_setpoint = plot([0 100], [0.018 0.018], 'r--', 'LineWidth', 1);
legend('Signal', 'Setpoint');

subplot(2,2,2); % aio1out trace
h_out = plot(nan, nan, 'r-', 'LineWidth', 1.5);
title('AIO1Out Signal (Live)');
xlabel('Sample');
ylabel('Voltage (V)');
grid on;

subplot(2,2,3); % Time series of averages
h_avg_in = animatedline('Color', 'b', 'LineWidth', 2);
h_avg_out = animatedline('Color', 'r', 'LineWidth', 2);
title('Average Values vs Time');
xlabel('Time (s)');
ylabel('Voltage (V)');
legend('MainIn Avg', 'AIO1Out Avg');
grid on;

subplot(2,2,4); % Statistics display
ax_stats = gca;
axis off;

%% Monitoring Loop
numPoints = 100;
startTime = tic;
iteration = 0;

% Storage for time series
max_points = 200;
time_history = [];
main_in_history = [];
aio1_out_history = [];

try
    while ishandle(fig)
        iteration = iteration + 1;
        current_time = toc(startTime);
        
        % Check lock status
        lock_status = dl.pid1.getLockStatus();
        
        % Acquire data
        main_in_data = dl.scope.acquire(1, numPoints);
        aio1_out_data = dl.scope.acquire(2, numPoints);
        
        % Calculate statistics
        main_in_avg = mean(main_in_data);
        aio1_out_avg = mean(aio1_out_data);
        main_in_rms = std(main_in_data);
        aio1_out_rms = std(aio1_out_data);
        error_signal = main_in_avg - 0.018; % Error from setpoint
        
        % Update traces (subplot 1 & 2)
        subplot(2,2,1);
        set(h_in, 'XData', 1:length(main_in_data), 'YData', main_in_data);
        ylim([min(main_in_data)-0.01, max(main_in_data)+0.01]);
        title(sprintf('MainIn | Lock: %s | Avg: %.6f V | RMS: %.6f V', ...
            iif(lock_status, 'ON', 'OFF'), main_in_avg, main_in_rms));
        
        subplot(2,2,2);
        set(h_out, 'XData', 1:length(aio1_out_data), 'YData', aio1_out_data);
        ylim([min(aio1_out_data)-0.01, max(aio1_out_data)+0.01]);
        title(sprintf('aio1out | Avg: %.6f V | RMS: %.6f V', ...
            aio1_out_avg, aio1_out_rms));
        
        % Update time series (subplot 3)
        time_history(end+1) = current_time;
        main_in_history(end+1) = main_in_avg;
        aio1_out_history(end+1) = aio1_out_avg;
        
        % Keep only last max_points
        if length(time_history) > max_points
            time_history = time_history(end-max_points+1:end);
            main_in_history = main_in_history(end-max_points+1:end);
            aio1_out_history = aio1_out_history(end-max_points+1:end);
        end
        
        subplot(2,2,3);
        clearpoints(h_avg_in);
        clearpoints(h_avg_out);
        addpoints(h_avg_in, time_history, main_in_history);
        addpoints(h_avg_out, time_history, aio1_out_history);
        xlim([max(0, current_time-60), current_time+1]);
        
        % Update statistics display (subplot 4)
        subplot(2,2,4);
        cla;
        axis off;
        
        stats_text = {
            '\bf\fontsize{14}PID Parameters:',
            sprintf('Gain:       %.2f', 1.0),
            sprintf('P:          %.2f', 1000000.0),
            sprintf('I:          %.2f', 150.0),
            sprintf('D:          %.2f', 8742.0),
            sprintf('Setpoint:   %.6f V', 0.018),
            '',
            '\bf\fontsize{14}Current Status:',
            sprintf('Lock:       %s', iif(lock_status, '\color{green}ON', '\color{red}OFF')),
            sprintf('Error:      %.6f V', error_signal),
            sprintf('Runtime:    %.1f s', current_time),
            sprintf('Updates:    %d', iteration)
        };
        
        text(0.1, 0.9, stats_text, ...
            'VerticalAlignment', 'top', ...
            'FontName', 'FixedWidth', ...
            'FontSize', 10, ...
            'Interpreter', 'tex');
        
        % Console output (reduced frequency)
        if mod(iteration, 5) == 0
            fprintf('[%6.1fs] Lock: %d | MainIn: %.6f V | aio1out: %.6f V | Error: %.6f V\n', ...
                current_time, lock_status, main_in_avg, aio1_out_avg, error_signal);
        end
        
        drawnow limitrate;
        pause(0.1);
    end
catch ME
    fprintf('\nMonitoring stopped: %s\n', ME.message);
end

%% Cleanup
if ishandle(fig)
    close(fig);
end
dl.pid1.unlock();
dl.disconnect();
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