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
#include <iomanip>  // For std::setw

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
#include "Steering_t.hpp"

#define OUTPUT_WIDTH 33

void process_data(dds::sub::DataReader<dds::actuation::SteeringDesired> reader, dds::pub::DataWriter<dds::actuation::SteeringActual> writer)
{
    // Take all samples
    dds::sub::LoanedSamples<dds::actuation::SteeringDesired> samples = reader.take();
    for (auto sample : samples) {
        if (sample.info().valid()) {
            writer.write(dds::actuation::SteeringActual(sample.data().position()));
        }
    }

    return;
} // The LoanedSamples destructor returns the loan

void handle_status(dds::sub::DataReader<dds::actuation::SteeringDesired> reader, 
                   dds::pub::DataWriter<dds::actuation::SteeringActual> writer){
    bool safety_position(false);

    dds::core::status::StatusMask status_mask = reader.status_changes();

    // Check for liveliness status
    if ((status_mask & dds::core::status::StatusMask::liveliness_changed()).any()) {
        auto liveliness_status = reader.liveliness_changed_status();
        if (liveliness_status.not_alive_count_change() > 0) {
            std::cout << std::left << std::setw(OUTPUT_WIDTH) << std::setfill(' ')
                      << "Liveliness lost from controller:" << liveliness_status.last_publication_handle() << std::endl;
        }
        if (liveliness_status.alive_count() == 0) {
            safety_position = true;
        }
        return;
    }

    // Check for subscription matched status
    if((status_mask & dds::core::status::StatusMask::subscription_matched()).any()) {
        auto subscription_status = reader.subscription_matched_status();
        if (subscription_status.current_count_change() > 0) {
            std::cout << std::left << std::setw(OUTPUT_WIDTH) << std::setfill(' ')
                      << "Matched controller:" << subscription_status.last_publication_handle() << std::endl;
        } else {
            std::cout << std::left << std::setw(OUTPUT_WIDTH) << std::setfill(' ')
                      << "Unmatched controller:" << subscription_status.last_publication_handle() << std::endl;
        }
        if( subscription_status.current_count() == 0) {
            safety_position = true;
        }
    }

    // Check for deadline status
    if((status_mask & dds::core::status::StatusMask::requested_deadline_missed()).any()) {
        auto deadline_status = reader.requested_deadline_missed_status();
        std::cout << "Deadline missed from controller." << std::endl;
    }

    if(safety_position) {
        writer.write(dds::actuation::SteeringActual(0));
        std::cout << "Writing Steering Position: 0" << std::endl;
    }
}

void run_publisher_application(unsigned int domain_id)
{
    // DDS objects behave like shared pointers or value types
    // (see https://community.rti.com/best-practices/use-modern-c-types-correctly)

    // When using user-generated types, you must register the type with RTI
    // Connext DDS before creating the participants and the rest of the entities
    // in your system
    rti::domain::register_type<dds::actuation::SteeringActual>("dds::actuation::SteeringActual");
    rti::domain::register_type<dds::actuation::SteeringDesired>("dds::actuation::SteeringDesired");

    // Create the participant, changing the domain id from the one in the
    // configuration
    rti::domain::DomainParticipantConfigParams params(domain_id);

    // Create the participant
    auto default_provider = dds::core::QosProvider::Default();
    dds::domain::DomainParticipant participant =
    default_provider->create_participant_from_config(
        "DriveParticipantLib::SteeringColumn",
        params);

    // Lookup the DataWriter from the configuration
    dds::pub::DataWriter<dds::actuation::SteeringActual> status_writer =
    rti::pub::find_datawriter_by_name<dds::pub::DataWriter<dds::actuation::SteeringActual>>(
        participant,
        "outputs::Steering_writer");

    // Lookup the DataReader from the configuration
    dds::sub::DataReader<dds::actuation::SteeringDesired> command_reader =
    rti::sub::find_datareader_by_name<dds::sub::DataReader<dds::actuation::SteeringDesired>>(
        participant,
        "inputs::Steering_reader");

    // Create a ReadCondition for any data received on this reader and set a
    // handler to process the data
    dds::sub::cond::ReadCondition read_condition(
        command_reader,
        dds::sub::status::DataState::any(),
        [command_reader, status_writer]() { process_data(command_reader, status_writer); });

    // Enable the statuses to monitor
    dds::core::cond::StatusCondition status_condition(command_reader);
    status_condition.enabled_statuses(
        dds::core::status::StatusMask::subscription_matched() |
        dds::core::status::StatusMask::requested_deadline_missed() |
        dds::core::status::StatusMask::liveliness_changed());

    // Set a handler for the StatusCondition
    status_condition.extensions().handler([command_reader, status_writer]() {
        handle_status(command_reader, status_writer);
    });

    // WaitSet will be woken when the attached condition is triggered
    dds::core::cond::WaitSet waitset;
    waitset += read_condition;
    waitset += status_condition;

    // Enable the participant and underlying entities recursively
    participant.enable();

    std::cout << "Actuator loop starting..." << std::endl;
    while (!application::shutdown_requested) {
        waitset.dispatch(dds::core::Duration(1));
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
        run_publisher_application(arguments.domain_id);
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
