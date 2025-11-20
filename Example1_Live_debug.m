%% Working Live Monitor - Using Direct Queries (FIXED)
clear all;
close all;

% Connect
dl = DigiLock110('10.129.216.210', 60001, 'Verbose', false);
dl.connect();

% Configure scope channels
fprintf('Configuring scope...\n');
dl.scope.setChannel(1, 'main in');
dl.scope.setChannel(2, 'aio1 out');
pause(0.3);

% Configure PID
fprintf('Configuring PID...\n');
dl.pid1.setInput('main in');
dl.pid1.setOutput('aio1 out');
dl.pid1.setGain(1.0);
dl.pid1.setP(1000000.0);
dl.pid1.setI(150.0);
dl.pid1.setD(8742.0);
dl.pid1.setSetpoint(0.018);

% Lock
dl.pid1.lock();
fprintf('Locked! Starting monitoring...\n\n');

% Create figure
fig = figure('Name', 'DigiLock 110 Live Monitor', ...
             'NumberTitle', 'off', ...
             'Position', [100, 100, 1400, 700]);

% Subplots
subplot(2,2,1);
h_main_in = animatedline('Color', 'b', 'LineWidth', 2);
hold on;
plot([0 100], [0.018 0.018], 'r--', 'LineWidth', 2);
title('Main In Mean vs Time');
xlabel('Time (s)');
ylabel('Voltage (V)');
grid on;
legend('Main In', 'Setpoint');

subplot(2,2,2);
h_aio1_out = animatedline('Color', 'r', 'LineWidth', 2);
title('AIO1 Out Mean vs Time');
xlabel('Time (s)');
ylabel('Voltage (V)');
grid on;

subplot(2,2,3);
h_error = animatedline('Color', 'k', 'LineWidth', 2);
hold on;
plot([0 100], [0 0], 'r--', 'LineWidth', 1);
title('Error (Main In - Setpoint) vs Time');
xlabel('Time (s)');
ylabel('Error (V)');
grid on;

subplot(2,2,4);
ax_stats = gca;
axis off;

% Storage
startTime = tic;
time_history = [];
main_in_history = [];
aio1_out_history = [];
error_history = [];
main_in_rms_history = [];

iteration = 0;
max_points = 200;

fprintf('Time\t| Lock | MainIn\t| AIO1Out\t| Error\t\t| MainIn RMS\n');
fprintf('-------------------------------------------------------------------\n');

try
    while ishandle(fig)
        iteration = iteration + 1;
        current_time = toc(startTime);
        
        % Get lock status
        lock_status = dl.pid1.getLockStatus();
        
        % Query scope values directly - FIXED: use dl.queryNumeric not dl.parent.queryNumeric
        main_in_mean = dl.queryNumeric('scope:ch1:mean?');
        main_in_rms = dl.queryNumeric('scope:ch1:rms?');
        aio1_out_mean = dl.queryNumeric('scope:ch2:mean?');
        aio1_out_rms = dl.queryNumeric('scope:ch2:rms?');
        
        error_val = main_in_mean - 0.018;
        
        % Store history
        time_history(end+1) = current_time;
        main_in_history(end+1) = main_in_mean;
        aio1_out_history(end+1) = aio1_out_mean;
        error_history(end+1) = error_val;
        main_in_rms_history(end+1) = main_in_rms;
        
        % Keep last max_points
        if length(time_history) > max_points
            time_history = time_history(end-max_points+1:end);
            main_in_history = main_in_history(end-max_points+1:end);
            aio1_out_history = aio1_out_history(end-max_points+1:end);
            error_history = error_history(end-max_points+1:end);
            main_in_rms_history = main_in_rms_history(end-max_points+1:end);
        end
        
        % Update plots
        subplot(2,2,1);
        clearpoints(h_main_in);
        addpoints(h_main_in, time_history, main_in_history);
        xlim([max(0, current_time-60), current_time+1]);
        if ~isempty(main_in_history)
            ylim([min(main_in_history)-0.002, max(main_in_history)+0.002]);
        end
        
        subplot(2,2,2);
        clearpoints(h_aio1_out);
        addpoints(h_aio1_out, time_history, aio1_out_history);
        xlim([max(0, current_time-60), current_time+1]);
        
        subplot(2,2,3);
        clearpoints(h_error);
        addpoints(h_error, time_history, error_history);
        xlim([max(0, current_time-60), current_time+1]);
        if ~isempty(error_history)
            ylim([min(error_history)-0.001, max(error_history)+0.001]);
        end
        
        % Update stats
        subplot(2,2,4);
        cla;
        axis off;
        
        stats_text = {
            '\bf\fontsize{12}PID Status:',
            sprintf('\\fontsize{10}Lock:       %s', iif(lock_status, '\color{green}LOCKED', '\color{red}UNLOCKED')),
            '',
            '\bf\fontsize{12}Current Values:',
            sprintf('\\fontsize{10}\\color{black}Main In:    %.6f V', main_in_mean),
            sprintf('AIO1 Out:   %.6f V', aio1_out_mean),
            sprintf('Error:      %.6f V', error_val),
            '',
            '\bf\fontsize{12}Signal Quality:',
            sprintf('\\fontsize{10}Main In RMS: %.6f V', main_in_rms),
            sprintf('AIO1 Out RMS: %.6f V', aio1_out_rms),
            '',
            '\bf\fontsize{12}Runtime:',
            sprintf('\\fontsize{10}Time:       %.1f s', current_time),
            sprintf('Updates:    %d', iteration)
        };
        
        text(0.05, 0.95, stats_text, ...
            'VerticalAlignment', 'top', ...
            'FontName', 'FixedWidth', ...
            'FontSize', 9, ...
            'Interpreter', 'tex');
        
        % Console output
        if mod(iteration, 5) == 0
            fprintf('%.1fs\t| %d    | %.6f\t| %.6f\t| %+.6f\t| %.6f\n', ...
                current_time, lock_status, main_in_mean, aio1_out_mean, ...
                error_val, main_in_rms);
        end
        
        drawnow limitrate;
        pause(0.2);
    end
catch ME
    fprintf('\nError: %s\n', ME.message);
end

% Cleanup
if ishandle(fig), close(fig); end
dl.pid1.unlock();
dl.disconnect();
fprintf('\n=== Monitoring Complete ===\n');

function out = iif(condition, trueVal, falseVal)
    if condition
        out = trueVal;
    else
        out = falseVal;
    end
end
