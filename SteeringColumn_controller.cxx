/*
* (c) Copyright, Real-Time Innovations, 2020.  All rights reserved.
* RTI grants Licensee a license to use, modify, compile, and create derivative
* works of the software solely for use with RTI Connext DDS. Licensee may
* redistribute copies of the software provided that all such copies are subject
* to this license. The software is provided "as is", with no warranty of any
* type, including any warranty for fitness for any purpose. RTI is under no
* obligation to maintain or support the software. RTI shall not be liable for
* any incidental or consequential damages arising out of the use or inability
* to use the software.
*/

#include <iostream>

#include <dds/pub/ddspub.hpp>
#include <dds/sub/ddssub.hpp>
#include <rti/util/util.hpp>      // for sleep()
#include <rti/config/Logger.hpp>  // for logging
// alternatively, to include all the standard APIs:
//  <dds/dds.hpp>
// or to include both the standard APIs and extensions:
//  <rti/rti.hpp>
//
// For more information about the headers and namespaces, see:
//    https://community.rti.com/static/documentation/connext-dds/7.3.0/doc/api/connext_dds/api_cpp2/group__DDSNamespaceModule.html
// For information on how to use extensions, see:
//    https://community.rti.com/static/documentation/connext-dds/7.3.0/doc/api/connext_dds/api_cpp2/group__DDSCpp2Conventions.html

#include "application.hpp"  // for command line parsing and ctrl-c
#include "SteeringTypes.hpp"

void run_publisher_application(unsigned int domain_id, unsigned int sample_count)
{
    // DDS objects behave like shared pointers or value types
    // (see https://community.rti.com/best-practices/use-modern-c-types-correctly)

    // When using user-generated types, you must register the type with RTI
    // Connext DDS before creating the participants and the rest of the entities
    // in your system
    rti::domain::register_type<SteeringCommand>("SteeringCommand");
    rti::domain::register_type<SteeringStatus>("SteeringStatus");

    // Create the participant, changing the domain id from the one in the
    // configuration
    rti::domain::DomainParticipantConfigParams params(domain_id);

    // Create the participant
    auto default_provider = dds::core::QosProvider::Default();
    dds::domain::DomainParticipant participant =
    default_provider->create_participant_from_config(
        "SteeringColumnParticipantLibrary::Controller",
        params);

    // Lookup the DataWriter from the configuration
    dds::pub::DataWriter<SteeringCommand> command_writer =
    rti::pub::find_datawriter_by_name<dds::pub::DataWriter<SteeringCommand>>(
        participant,
        "Publisher::SteeringCommandTopicWriter");

    // Lookup the DataReader from the configuration
    dds::sub::DataReader<SteeringStatus> status_reader =
    rti::sub::find_datareader_by_name<dds::sub::DataReader<SteeringStatus>>(
        participant,
        "Publisher::SteeringStatusTopicReader");

    // Enable the participant and underlying entities recursively
    participant.enable();

    SteeringCommand data;
    // Main loop, write data
    for (unsigned int samples_written = 0;
    !application::shutdown_requested && samples_written < sample_count;
    samples_written++) {
        // Modify the data to be written here
        std::cout << "Writing SteeringCommand, count " << samples_written << std::endl;

        command_writer.write(data);

        // Send once every second
        rti::util::sleep(dds::core::Duration(1));
    }
}

int main(int argc, char *argv[])
{

    using namespace application;

    // Parse arguments and handle control-C
    auto arguments = parse_arguments(argc, argv);
    if (arguments.parse_result == ParseReturn::exit) {
        return EXIT_SUCCESS;
    } else if (arguments.parse_result == ParseReturn::failure) {
        return EXIT_FAILURE;
    }
    setup_signal_handlers();

    // Sets Connext verbosity to help debugging
    rti::config::Logger::instance().verbosity(arguments.verbosity);

    try {
        run_publisher_application(arguments.domain_id, arguments.sample_count);
    } catch (const std::exception& ex) {
        // This will catch DDS exceptions
        std::cerr << "Exception in run_publisher_application(): " << ex.what()
        << std::endl;
        return EXIT_FAILURE;
    }

    // Releases the memory used by the participant factory.  Optional at
    // application exit
    dds::domain::DomainParticipant::finalize_participant_factory();

    return EXIT_SUCCESS;
}
