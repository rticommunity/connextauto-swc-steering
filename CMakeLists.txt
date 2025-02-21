#******************************************************************************
# (C) Copyright 2020-2025 Real-Time Innovations, Inc.  All rights reserved.
#
# The use of this software is governed by the terms specified in the 
# RTI Labs License Agreement, available at https://www.rti.com/terms/RTILabs. 
#
# By accessing, downloading, or otherwise using this software, you agree to 
# be bound by those terms.
#*****************************************************************************

cmake_minimum_required(VERSION 3.20)
project(connextauto-swc-template)

if(NOT databus_SOURCE_DIR) # "databus" project is NOT defined in current build
    include(${DATABUS_PROJECT_DIR}/build-helpers/cmake/init.cmake)
endif()

#-----------------------------------------------------------------------------

set(APPLICATIONS)

if("${RTI_CONNEXT_SDK}" MATCHES "pro")
    #-------------------------------------------------------------------------
    # Connext SDK: Professional
    #-------------------------------------------------------------------------
    set(APPLICATIONS my_publisher)

    add_executable(my_publisher
        "${CMAKE_CURRENT_SOURCE_DIR}/srcCxx/pro/publisher.cxx"
        "${CMAKE_CURRENT_SOURCE_DIR}/srcCxx/pro/Application.cxx"
        "${CMAKE_CURRENT_SOURCE_DIR}/srcCxx/pro/Application.h"
        )

    target_link_libraries(my_publisher
        PRIVATE
        C++_${RTI_CONNEXT_SDK}_types_lib
        )

elseif("${RTI_CONNEXT_SDK}" MATCHES "micro")
    #-------------------------------------------------------------------------
    # Connext SDK: Micro
    #-------------------------------------------------------------------------
    set(APPLICATIONS my_subscriber)

    add_executable(my_subscriber
        "${CMAKE_CURRENT_SOURCE_DIR}/srcC/micro/subscriber.c"
        "${CMAKE_CURRENT_SOURCE_DIR}/srcC/micro/Application.c"
        "${CMAKE_CURRENT_SOURCE_DIR}/srcC/micro/Application.h"
        )

    target_link_libraries(my_subscriber
        PRIVATE
        C_${RTI_CONNEXT_SDK}_types_lib
        RTIConnextDDSMicro::discdpse
        RTIConnextDDSMicro::discdpde
        RTIConnextDDSMicro::whsm
        RTIConnextDDSMicro::rhsm
        )

else()
    set(APPLICATIONS)

    message(NOTICE "No rules to build for RTI_CONNEXT_SDK")

endif()

#-----------------------------------------------------------------------------

install(
    TARGETS ${APPLICATIONS}
    CONFIGURATIONS Debug Release
    RUNTIME DESTINATION "${INSTALL_RUNTIME_OUTPUT_DIRECTORY}"
    ARCHIVE DESTINATION "${INSTALL_ARCHIVE_OUTPUT_DIRECTORY}"
    LIBRARY DESTINATION "${INSTALL_LIBRARY_OUTPUT_DIRECTORY}"
    )

#-----------------------------------------------------------------------------
