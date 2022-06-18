#[=======================================================================[.rst:
FindERPC
--------

Find eRPC

Signature::

find_package(ERPC REQUIRED [COMPONENTS <components>])

Following components are available

- ``erpcgen``: erpcgen tool
- ``erpcsniffer``: erpcsniffer tool
- ``lib``: eRPC runtime C/C++ library

This module looks for eRPC.  This module defines the following values:

``ERPC_FOUND``: True if erpc has been found.
``eRPC::erpcgen``
``eRPC::erpcsniffer``
``eRPC::lib``
#]=======================================================================]


set(_ERPC_NAMESPACE "eRPC")

macro(_erpc_find_erpc_gen)
  find_program(ERPC_GEN_EXECUTABLE erpcgen REQUIRED)
  mark_as_advanced(ERPC_GEN_EXECUTABLE)

  if(ERPC_GEN_EXECUTABLE)
    # Create an imported target for erpcgen
    if(NOT TARGET ${_ERPC_NAMESPACE}::erpcgen)
      add_executable(${_ERPC_NAMESPACE}::erpcgen IMPORTED GLOBAL)
      set_target_properties(${_ERPC_NAMESPACE}::erpcgen PROPERTIES
        IMPORTED_LOCATION "${ERPC_GEN_EXECUTABLE}"
        )
    endif()
  endif()
endmacro()

macro(_erpc_find_erpc_sniffer)
  find_program(ERPC_SNIFFER_EXECUTABLE erpcsniffer REQUIRED)
  mark_as_advanced(ERPC_SNIFFER_EXECUTABLE)

  if(ERPC_SNIFFER_EXECUTABLE)
    # Create an imported target for erpcsniffer
    if(NOT TARGET ${_ERPC_NAMESPACE}::erpcsniffer)
      add_executable(${_ERPC_NAMESPACE}::erpcsniffer IMPORTED GLOBAL)
      set_target_properties(${_ERPC_NAMESPACE}::erpcsniffer PROPERTIES
        IMPORTED_LOCATION "${ERPC_SNIFFER_EXECUTABLE}"
        )
    endif()
  endif()
endmacro()

macro(_erpc_find_erpc_lib)
  find_library(ERPC_LIB erpc REQUIRED
    HINTS
    $ENV{HOME}/.local/lib
    /usr/local/lib/
    /usr/lib/
    CMAKE_FIND_ROOT_PATH_BOTH
    )
  set(RELEVANT_HEADERS erpc_client_setup.h erpc_server_setup.h erpc_port.h
    erpc_serial.h erpc_threading.h erpc_common.h erpc_basic_codec.h erpc_client_server_common.h
    erpc_serial_transport.h
    )
  find_path(ERPC_INCLUDE_DIRS
    REQUIRED
    NAMES ${RELEVANT_HEADERS}
    HINTS
    $ENV{HOME}/.local/include
    /usr/local/include/
    /usr/include/
    PATH_SUFFIXES erpc
    ${REQUIRED}
    CMAKE_FIND_ROOT_PATH_BOTH
    )

  if (ERPC_INCLUDE_DIRS AND ERPC_LIB)
    add_library(${_ERPC_NAMESPACE}::lib STATIC IMPORTED GLOBAL)
    set_target_properties(${_ERPC_NAMESPACE}::lib PROPERTIES
      IMPORTED_LOCATION ${ERPC_LIB}
      INTERFACE_INCLUDE_DIRECTORIES "${ERPC_INCLUDE_DIRS}"
      )
  endif()
endmacro()

foreach(_comp IN LISTS ERPC_FIND_COMPONENTS)
  if (_comp STREQUAL "erpcgen")
    _erpc_find_erpc_gen()
  elseif (_comp STREQUAL "erpcsniffer")
    _erpc_find_erpc_sniffer()
  elseif (_comp STREQUAL "lib")
    _erpc_find_erpc_lib()
  else()
    message(WARNING "${_comp} is not a valid Doxygen component")
    set(ERPC_${_comp}_FOUND FALSE)
    continue()
  endif()

  if(TARGET ${_ERPC_NAMESPACE}::${_comp})
    set(ERPC_${_comp}_FOUND TRUE)
  else()
    set(ERPC_${_comp}_FOUND FALSE)
  endif()
endforeach()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(ERPC REQUIRED_VARS ERPC_GEN_EXECUTABLE HANDLE_COMPONENTS)

#[=======================================================================[.rst:
ERPCGetPrefix
-------------
Helper function that, given a eRPC IDL file, returns prefix that all the
generated files will have.

Signature::

erpc_get_prefix(<IDL_FILE> <PREFIX>)

The required input parameters are:

- ``IDL_FILE`` (input): the eRPC IDL file
- ``PREFIX`` (output): the prefix
#]=======================================================================]
function(ERPC_GET_PREFIX _IDF_FILE _PREFIX)
  # By default PREFIX is the file name without .erpc extension
  # If the program statement is used in the IDF file, then the prefix will
  # be the identifier following the program keyword.

  get_filename_component(IDF_FILE_NAME "${_IDF_FILE}" NAME_WE)
  set(PREFIX ${IDF_FILE_NAME})

  # If _IDF_FILE changes, re-run CMake's configuration phase
  # so that we can re-read from _IDF_FILE and react to potential changes
  set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS ${_IDF_FILE})
  file(READ "${_IDF_FILE}" IDF_FILE_CONTENT)
  string(REGEX MATCH "program ([_a-zA-Z][_a-zA-Z0-9]*)" _ ${IDF_FILE_CONTENT})
  set(PROGRAM_NAME "${CMAKE_MATCH_1}")
  if (PROGRAM_NAME)
    set(PREFIX ${PROGRAM_NAME})
  endif()

  set(${_PREFIX} ${PREFIX} PARENT_SCOPE)
endfunction()

#[=======================================================================[.rst:
_ERPCGetCOutputs
---------------
Helper function that, given a eRPC IDL file, the designated generation output
directory and a list of groups, returns the files that erpcgen will generate
for the C/C++ language.

Signature::

  _erpc_get_c_outputs(<IDL_FILE> <OUTPUT_DIR> <GROUPS>
                      <SOURCES> <HEADERS>)

The required input parameters are:

- ``IDL_FILE``: the eRPC IDL file
- ``OUTPUT_DIR``: list of @group annotation that have been used in the
IDL files.
- ``GROUPS``: list of @group annotation that have been used in the
IDL files.

The ouput parameters are:

- ``SOURCES``:
- ``HEADERS``:
#]=======================================================================]
function(_ERPC_GET_C_OUTPUTS _IDF_FILE _OUTPUT_DIR _GROUPS _SOURCES _HEADERS)
  erpc_get_prefix(${_IDF_FILE} PREFIX)
  list(LENGTH _GROUPS GROUPS_LEN)

  set(SOURCES "")
  set(HEADERS "")

  if (GROUPS_LEN EQUAL 0)
    list(APPEND SOURCES
      ${_OUTPUT_DIR}/${PREFIX}_client.cpp
      ${_OUTPUT_DIR}/${PREFIX}_server.cpp
      )
    list(APPEND HEADERS
      ${_OUTPUT_DIR}/${PREFIX}.h
      ${_OUTPUT_DIR}/${PREFIX}_server.h
      )
  else()
    foreach(GROUP ${GROUPS})
      list(APPEND SOURCES
        ${_OUTPUT_DIR}/${PREFIX}_${GROUP}_client.cpp
        ${_OUTPUT_DIR}/${PREFIX}_${GROUP}_server.cpp
        )
      list(APPEND HEADERS
        ${_OUTPUT_DIR}/${PREFIX}_${GROUP}.h
        ${_OUTPUT_DIR}/${PREFIX}_${GROUP}_server.h
        )
    endforeach()
  endif()

  set(${_SOURCES} ${SOURCES} PARENT_SCOPE)
  set(${_HEADERS} ${HEADERS} PARENT_SCOPE)
endfunction()

#[=======================================================================[.rst:
ERPCAddCTargets
---------------
Helper function that, given a eRPC IDL file, the designated generation output
directory and a list of groups, creates the appropriate C static library
targets, as documented in ERPCAddIDLTarget.

Signature::

  _erpc_add_c_targets(<IDL_FILE> <TARGET_PREFIX> <OUTPUT_DIR> <GROUPS> <SERVER_DEPENDS>)
#]=======================================================================]
function(_ERPC_ADD_C_TARGETS _IDF_FILE _TARGET_PREFIX _OUTPUT_DIR _GROUPS _SERVER_DEPENDS)
  _erpc_get_c_outputs(${_IDL_FILE} ${_OUTPUT_DIR} "${_GROUPS}" SOURCES HEADERS)

  add_custom_command(OUTPUT ${SOURCES} ${HEADERS}
    COMMAND eRPC::erpcgen --generate c --output ${OUTPUT_DIR} ${_IDL_FILE}
    DEPENDS ${_IDL_FILE}
    WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}
    VERBATIM
    )

  list(LENGTH _SERVER_DEPENDS SERVER_DEPENDS_LEN)

  set(SERVER_SOURCES ${SOURCES})
  list(FILTER SERVER_SOURCES INCLUDE REGEX "server.cpp")
  add_library(${_TARGET_PREFIX}_server STATIC EXCLUDE_FROM_ALL)
  add_library(${_TARGET_PREFIX}::server ALIAS ${_TARGET_PREFIX}_server)
  target_sources(${_TARGET_PREFIX}_server
    PRIVATE
    ${SERVER_SOURCES}
    )
  target_link_libraries(${_TARGET_PREFIX}_server PUBLIC eRPC::lib)
  if (SERVER_DEPENDS_LEN GREATER 0)
    target_link_libraries(${_TARGET_PREFIX}_server PRIVATE "${_SERVER_DEPENDS}")
  endif()

  set(CLIENT_SOURCES ${SOURCES})
  list(FILTER CLIENT_SOURCES INCLUDE REGEX "client.cpp")
  add_library(${_TARGET_PREFIX}_client STATIC EXCLUDE_FROM_ALL)
  add_library(${_TARGET_PREFIX}::client ALIAS ${_TARGET_PREFIX}_client)
  target_sources(${_TARGET_PREFIX}_client
    PRIVATE
    ${CLIENT_SOURCES}
    )
  target_link_libraries(${_TARGET_PREFIX}_client PUBLIC eRPC::lib)

  list(LENGTH _GROUPS GROUPS_LEN)
  if (GROUPS_LEN GREATER 0)
    foreach(GROUP ${_GROUPS})
      set(GROUP_SERVER_SOURCES ${SERVER_SOURCES})
      list(FILTER GROUP_SERVER_SOURCES INCLUDE REGEX "${GROUP}_server.cpp")
      add_library(${_TARGET_PREFIX}_${GROUP}_server STATIC EXCLUDE_FROM_ALL)
      add_library(${_TARGET_PREFIX}::${GROUP}::server ALIAS ${_TARGET_PREFIX}_${GROUP}_server)
      target_sources(${_TARGET_PREFIX}_${GROUP}_server
        PRIVATE
        ${GROUP_SERVER_SOURCES}
        )
      target_link_libraries(${_TARGET_PREFIX}_${GROUP}_server PUBLIC eRPC::lib)
      if (SERVER_DEPENDS_LEN GREATER 0)
        target_link_libraries(${_TARGET_PREFIX}_${GROUP}_server PRIVATE "${_SERVER_DEPENDS}")
      endif()

      set(GROUP_CLIENT_SOURCES ${CLIENT_SOURCES})
      list(FILTER GROUP_CLIENT_SOURCES INCLUDE REGEX "${GROUP}_client.cpp")
      add_library(${_TARGET_PREFIX}_${GROUP}_client STATIC EXCLUDE_FROM_ALL)
      add_library(${_TARGET_PREFIX}::${GROUP}::client ALIAS ${_TARGET_PREFIX}_${GROUP}_client)
      target_sources(${_TARGET_PREFIX}_${GROUP}_client
        PRIVATE
        ${GROUP_CLIENT_SOURCES}
        )
      target_link_libraries(${_TARGET_PREFIX}_${GROUP}_client PUBLIC eRPC::lib)
    endforeach()
  endif()
endfunction()

#[=======================================================================[.rst:
ERPCAddIDLTarget
----------------
Given a target name and eRPC IDL file, create static libraries (named based
on the given target name) that includes the generated C/C++ stub files as
source file.

Signature::

erpc_add_idl_target(<IDL_FILE>
  TARGET_PREFIX <target_prefix>
  [SEARCH_PATH <dir>]
  [OUTPUT_DIR <dir>]
  [GROUPS <dir>]
  [LANGUAGES <lang> [lang...]]
  [SERVER_DEPENDS <library target> [library targets...]]
  )

The required parameters are:

- ``IDL_FILE`` (input): the eRPC IDL file
- ``TARGET_PREFIX`` (input): The target prefix of the custom target that takes
care of protobuf files generation. By default is ${COMPONENT_LIB}-protobuf.
Use this if you need to have multiple protobuf targets associated with the
same component.

The optional parameters are:

- ``SEARCH_PATH`` (input): the directory that erpcgen uses to look for imports.
By default it's CMAKE_CURRENT_LIST_DIR.
- ``OUTPUT_DIR`` (input): the directory where the generated files will be
placed. By default it's CMAKE_CURRENT_LIST_DIR.
- ``GROUPS`` (input): list of @group annotation that have been used in the
IDL files.
- ``LANGUAGES`` (input): list of languages for which the stubs should be
generated. Currently supports: `c` and `python`. By default it's `c`.
- ``SERVER_DEPENDS`` (input): list of library targets that provide the
  functions implementations of the services that are provided by the current
  program.

This function creates the following static library targets

``${TARGET_PREFIX}::server``
``${TARGET_PREFIX}::client``

If GROUPS is non-empty, static library targets with names:

``${TARGET_PREFIX}::${group}::server``
``${TARGET_PREFIX}::${group}::client``

are created for each group.

If LANGUAGES contains python, then the custom target named
``${TARGET_PREFIX}_python`` is created. This custom target is created with the
``ALL`` option, so it is added to the default build target and it will be run
every time. To force the generation of the Python eRPC modules when you're not
using the default build target (e.g. you're doing ``make flash`` instead of
``make``), you may want to add this custom target as a dependency of of some
application level targets using ``add_dependencies``.
#]=======================================================================]
function(ERPC_ADD_IDL_TARGET _IDL_FILE)
  cmake_parse_arguments(PARSE_ARGV 1 "_FUNC_NAMED_PARAMETERERS" "" "OUTPUT_DIR;TARGET_PREFIX;SEARCH_PATH" "LANGUAGES;GROUPS;SERVER_DEPENDS")

  if (NOT DEFINED _FUNC_NAMED_PARAMETERERS_TARGET_PREFIX)
    message(FATAL_ERROR "TARGET_PREFIX is required")
  else()
    set(TARGET_PREFIX ${_FUNC_NAMED_PARAMETERERS_TARGET_PREFIX})
  endif()

  set(OUTPUT_DIR ${CMAKE_CURRENT_LIST_DIR})
  if (_FUNC_NAMED_PARAMETERERS_OUTPUT_DIR)
    get_filename_component(OUTPUT_DIR ${_FUNC_NAMED_PARAMETERERS_OUTPUT_DIR} ABSOLUTE)
  endif()

  set(SEARCH_PATH ${CMAKE_CURRENT_LIST_DIR})
  if (_FUNC_NAMED_PARAMETERERS_SEARCH_PATH)
    set(SEARCH_PATH ${_FUNC_NAMED_PARAMETERERS_SEARCH_PATH})
  endif()

  set(GROUPS "")
  if (_FUNC_NAMED_PARAMETERERS_GROUPS)
    set(GROUPS ${_FUNC_NAMED_PARAMETERERS_GROUPS})
  endif()

  set(SERVER_DEPENDS "")
  if (_FUNC_NAMED_PARAMETERERS_SERVER_DEPENDS)
    set(SERVER_DEPENDS ${_FUNC_NAMED_PARAMETERERS_SERVER_DEPENDS})
  endif()

  set(LANGUAGES c)
  if (_FUNC_NAMED_PARAMETERERS_LANGUAGES)
    set(LANGUAGES "${_FUNC_NAMED_PARAMETERERS_LANGUAGES}")
  endif()

  if ("c" IN_LIST LANGUAGES)
    _erpc_add_c_targets(${_IDL_FILE} ${TARGET_PREFIX} ${OUTPUT_DIR} "${GROUPS}" "${SERVER_DEPENDS}")
  endif()
  if ("python" IN_LIST LANGUAGES)
    add_custom_target(${TARGET_PREFIX}_python ALL
      COMMAND
      eRPC::erpcgen --generate py --output ${OUTPUT_DIR} ${_IDL_FILE}
      DEPENDS ${_IDF_FILE}
      COMMENT "Python stub generation by eRPC"
      WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}
      VERBATIM)
  endif()
endfunction()
