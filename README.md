# DigiLock 110 MATLAB Interface

This repository contains a MATLAB software interface for the Toptica DigiLock 110, a digital lock-in amplifier and laser control electronics unit. This interface allows for remote control and monitoring of the DigiLock 110's features via TCP/IP communication.

## Features

- **Object-Oriented Interface:** A clean, object-oriented MATLAB class (`DigiLock110`) that encapsulates all the instrument's functionalities.
- **Modular Design:** The interface is organized into sub-modules that correspond to the different functional blocks of the DigiLock 110, such as:
  - PID controllers (`pid1`, `pid2`)
  - Lock-in amplifier (`lockin`)
  - Pound-Drever-Hall module (`pdh`)
  - Scan generator (`scan`)
  - Auto-locking functionality (`autolock`)
  - Oscilloscope and spectrum analyzer (`scope`, `spectrum`)
- **Direct RCI Communication:** The interface communicates with the DigiLock 110 using its native Remote Control Interface (RCI) via TCP/IP.
- **Examples:** The repository includes example scripts, such as `simple_lock.m`, that demonstrate how to use the interface for common tasks.

## Requirements

- **Hardware:**
  - Toptica DigiLock 110 with an Ethernet connection.
- **Software:**
  - MATLAB (tested with R2016b and later).
  - MATLAB's Instrument Control Toolbox for TCP/IP communication.

## Installation

1. Clone or download this repository to your local machine.
2. Add the repository's root folder to your MATLAB path. You can do this using the `addpath` command in MATLAB:
   ```matlab
   addpath('path/to/Digilock110_Matlab');
   ```

## Usage

To use the interface, you first need to create an instance of the `DigiLock110` class, providing the IP address and port of your device.

```matlab
% Create a new DigiLock110 object
dl = DigiLock110('192.168.1.100', 60001);

% Connect to the device
dl.connect();

% --- Your code here ---
% You can now access the various sub-modules and their methods.
% For example, to set the gain of PID controller 1:
dl.pid1.setGain(5);

% --- End of your code ---

% Disconnect from the device
dl.disconnect();
```

### Available Modules

The `DigiLock110` object provides access to the following sub-modules:

- `dl.scan`: Controls the scan generator.
- `dl.pid1`: Controls PID controller 1.
- `dl.pid2`: Controls PID controller 2.
- `dl.lockin`: Controls the lock-in amplifier.
- `dl.pdh`: Controls the Pound-Drever-Hall module.
- `dl.autolock`: Controls the auto-locking functionality.
- `dl.offset`: Controls the offset adjustment.
- `dl.system`: Provides access to system-level settings.
- `dl.scope`: Controls the oscilloscope display.
- `dl.spectrum`: Controls the spectrum analyzer.

Each of these modules has its own set of methods for controlling the corresponding functionality. For example, the `DigiLockPID` class provides methods like `setGain`, `setP`, `setI`, `setD`, and `lock`.

### Basic Example

The `simple_lock.m` script provides a basic example of how to use the interface to set up a PID controller, engage a lock, and monitor the input and output signals.

```matlab
% Connect to DigiLock 110
dl = DigiLock110('192.168.1.100', 5000, 'Verbose', true);
dl.connect();

% Configure scope channels
dl.scope.setChannel(1, 'main in');
dl.scope.setChannel(2, 'main out');

% Configure PID 1
dl.pid1.setInput('main in');
dl.pid1.setOutput('main out');
dl.pid1.setP(1.0);
dl.pid1.setI(0.3);
dl.pid1.setD(0.05);

% Engage lock
dl.pid1.lock();

% Acquire and display data
main_in_data = dl.scope.acquire(1, 1000);
fprintf('MainIn average: %.6f V\n', mean(main_in_data));

% Disconnect
dl.disconnect();
```

### Advanced Topics

The `DigiLock110` class provides `write` and `query` methods for sending raw RCI commands directly to the device. This can be useful for accessing features that are not yet implemented in the class or for debugging purposes.

```matlab
% Send a command that doesn't expect a response
dl.write('pid1:proportional=1.0');

% Send a command and get a response
response = dl.query('pid1:proportional?');
disp(response);
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
