cmake_minimum_required(VERSION 3.5)
project(erpc_c)

set(AVAILABLE_PORTS freertos mbed memmanager mqx stdlib threadx zephyr)
if (NOT DEFINED ERPC_PORT)
	set(ERPC_PORT "stdlib")
endif()
if (NOT ERPC_PORT IN_LIST AVAILABLE_PORTS)
	message(FATAL_ERROR "${ERPC_PORT} is not a supported port")
endif()

set(TARGET_NAME ${PROJECT_NAME})
add_library(${TARGET_NAME} STATIC EXCLUDE_FROM_ALL "")
add_library(eRPC::lib ALIAS ${TARGET_NAME})
target_sources(${TARGET_NAME}
	PRIVATE
	infra/erpc_arbitrated_client_manager.cpp
	infra/erpc_basic_codec.cpp
	infra/erpc_client_manager.cpp
	infra/erpc_crc16.cpp
	infra/erpc_framed_transport.cpp
	infra/erpc_message_buffer.cpp
	infra/erpc_message_loggers.cpp
	infra/erpc_server.cpp
	infra/erpc_simple_server.cpp
	infra/erpc_transport_arbitrator.cpp
	infra/erpc_pre_post_action.cpp

	port/erpc_port_${ERPC_PORT}.cpp

	port/erpc_setup_extensions_freertos.cpp
	port/erpc_threading_pthreads.cpp
	port/erpc_threading_freertos.cpp
	port/erpc_threading_mbed.cpp
	port/erpc_threading_pthreads.cpp
	port/erpc_threading_threadx.cpp
	port/erpc_threading_win32.cpp
	port/erpc_threading_zephyr.cpp

	setup/erpc_arbitrated_client_setup.cpp
	setup/erpc_client_setup.cpp
	setup/erpc_setup_mbf_dynamic.cpp
	setup/erpc_setup_mbf_static.cpp
	setup/erpc_server_setup.cpp
	)
if (TARGET eRPCConfig)
	target_link_libraries(${TARGET_NAME}
		PUBLIC
		eRPCConfig
		)
endif()
target_include_directories(${TARGET_NAME}
	PUBLIC
	config/
	infra/
	port/
	setup/
	transports/
	)

set(AVAILABLE_TRANSPORTS dspi_master dspi_slave i2c_slave inter_thread_buffer
	mu serial spi_master spi_slave spidev_master tcp uart_cmsis usb_cdc)

foreach(TRANSPORT ${ERPC_TRANSPORTS})
	if (${TRANSPORT} IN_LIST AVAILABLE_TRANSPORTS)
		set(TARGET_NAME ${PROJECT_NAME}_transport_${TRANSPORT})
		add_library(${TARGET_NAME} STATIC EXCLUDE_FROM_ALL "")
		add_library(eRPC::transport::${TRANSPORT} ALIAS ${TARGET_NAME})
		target_sources(${TARGET_NAME}
			PRIVATE
			transports/erpc_${TRANSPORT}_transport.cpp
			setup/erpc_setup_${TRANSPORT}.cpp
			)
		target_link_libraries(${TARGET_NAME}
			PUBLIC
			eRPC::lib
			)
		if (TRANSPORT STREQUAL "serial")
			target_sources(${TARGET_NAME}
				PRIVATE
				port/erpc_serial.cpp
				)
		elseif (TRANSPORT STREQUAL "spidev_master")
			target_sources(${TARGET_NAME}
				PRIVATE
				port/erpc_spidev.cpp
				port/erpc_sysgpio.c
				)
		endif()
	else()
		message(WARNING "${TRANSPORT} is not a supported transport")
	endif()
endforeach()
