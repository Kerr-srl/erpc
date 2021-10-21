# eRPC library code

Directory Structure:

* `config`: Holds the user-editable erpc_config.h header. This file can either
  be edited in place, or copied to application code.
* `infra`: Contains C++ infrastructure code used to build server and client
  applications. For most use cases, the APIs in the setup/ folder are easier.
  Accessing the C++ layer directly is only required if you need to extend eRPC,
  or for atypical configurations.
* `port`: Contains the eRPC porting layer to adapt to different environments.
* `setup`: Contains a set of plain C APIs that wrap the C++ infrastructure,
  providing client and server init and deinit routines that greatly simplify
  eRPC usage in C-based projects. No knowledge of C++ is required to use these
  APIs.
* `transports`: Contains transport classes for the different methods of
  communication supported by eRPC. Some transports are applicable only to host
  PCs, while others are applicable only to embedded or multicore systems. Most
  transports have a corresponding C transport setup function in the setup/
  folder.

## CMake

This library can also be built using CMake, which makes integration into
existing CMake-based projects effortless.
This is particularly relevant for scenarios such as cross-compilation, where the
configured CMake cross compilation toolchain can be transparently used also in
building this library.

This library can be simply included using `add_subdirectory()`. You can also
use the find package script `FindERPC.cmake` provided in this repository.

It is possible to control some aspects of the compilation by defining the
following variables/targets before calling `add_subdirectory()`:

* `eRPCConfig` (optional): this interface target can be defined. In this
  interface target you can specify custom include directories and custom
  compilation definitions and options.
* `ERPC_PORT` (optional, defaults to `stdlib`): port to be used
   * freertos                                                       
   * mbed                                                           
   * memmanager                                                     
   * mqx                                                            
   * stdlib                                                         
   * threadx                                                        
   * zephyr                                                         
* `ERPC_TRANSPORTS` (optional): list of transports to be built

Once `add_subdirectory()` has been called, the following targets/variables
should be available:

* `eRPC::lib`: static library target
* `eRPC::transport::${transport}`: static library for each transport specified
  in ERPC_TRANSPORTS
