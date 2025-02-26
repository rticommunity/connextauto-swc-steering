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

// Listener that will be notified of DataReader events
class SteeringCommandDataReaderListener : public dds::sub::NoOpDataReaderListener<SteeringCommand> {
    public:
    // Notifications about data
    void on_requested_deadline_missed(
        dds::sub::DataReader<SteeringCommand>& reader,
        const dds::core::status::RequestedDeadlineMissedStatus& status)
        override
    {
        std::cout << "Requested deadline missed from controller: " << status.last_instance_handle() << std::endl;
    }
    void on_sample_rejected(
        dds::sub::DataReader<SteeringCommand>& reader,
        const dds::core::status::SampleRejectedStatus& status) override
    {
    }
    void on_sample_lost(
        dds::sub::DataReader<SteeringCommand>& reader,
        const dds::core::status::SampleLostStatus& status) override
    {
    }
    // Notifications about DataWriters
    void on_requested_incompatible_qos(
        dds::sub::DataReader<SteeringCommand>& reader,
        const dds::core::status::RequestedIncompatibleQosStatus& status)
        override
    {
    }
    void on_subscription_matched(
        dds::sub::DataReader<SteeringCommand>& reader,
        const dds::core::status::SubscriptionMatchedStatus& status) override
    {
        if(status.current_count_change() > 0) {
            std::cout << "Matched controller: " << status.last_publication_handle() << std::endl;
        } else {
            std::cout << "Unmatched controller: " << status.last_publication_handle() << std::endl;
        }
    }
    void on_liveliness_changed(
        dds::sub::DataReader<SteeringCommand>& reader,
        const dds::core::status::LivelinessChangedStatus& status) override
    {
        if(status.not_alive_count_change() > 0) {
            std::cout << "Liveliness lost from controller: " << status.last_publication_handle() << std::endl;
        }
    }
};

void process_data(dds::sub::DataReader<SteeringCommand> reader, dds::pub::DataWriter<SteeringStatus> writer)
{
    // Take all samples
    dds::sub::LoanedSamples<SteeringCommand> samples = reader.take();
    for (auto sample : samples) {
        if (sample.info().valid()) {
            writer.write(SteeringStatus(sample.data().position()));
        }
    }

    return;
} // The LoanedSamples destructor returns the loan

void run_publisher_application(unsigned int domain_id, unsigned int sample_count)
{
    // DDS objects behave like shared pointers or value types
    // (see https://community.rti.com/best-practices/use-modern-c-types-correctly)

    // When using user-generated types, you must register the type with RTI
    // Connext DDS before creating the participants and the rest of the entities
    // in your system
    rti::domain::register_type<SteeringStatus>("SteeringStatus");
    rti::domain::register_type<SteeringCommand>("SteeringCommand");

    // Create the participant, changing the domain id from the one in the
    // configuration
    rti::domain::DomainParticipantConfigParams params(domain_id);

    // Create the participant
    auto default_provider = dds::core::QosProvider::Default();
    dds::domain::DomainParticipant participant =
    default_provider->create_participant_from_config(
        "SteeringColumnParticipantLibrary::SteeringColumn",
        params);

    // Lookup the DataWriter from the configuration
    dds::pub::DataWriter<SteeringStatus> status_writer =
    rti::pub::find_datawriter_by_name<dds::pub::DataWriter<SteeringStatus>>(
        participant,
        "Publisher::SteeringStatusTopicWriter");

    // Lookup the DataReader from the configuration
    dds::sub::DataReader<SteeringCommand> command_reader =
    rti::sub::find_datareader_by_name<dds::sub::DataReader<SteeringCommand>>(
        participant,
        "Subscriber::SteeringCommandTopicReader");

    // Create a ReadCondition for any data received on this reader and set a
    // handler to process the data
    dds::sub::cond::ReadCondition read_condition(
        command_reader,
        dds::sub::status::DataState::any(),
        [command_reader, status_writer]() { process_data(command_reader, status_writer); });

    // WaitSet will be woken when the attached condition is triggered
    dds::core::cond::WaitSet waitset;
    waitset += read_condition;

    // Notify of all statuses in the listener except for new data, which we handle
    // in this thread with a WaitSet.
    auto status_mask = dds::core::status::StatusMask::all()
    & ~dds::core::status::StatusMask::data_available();

    // Create a DataReader, loading QoS profile from USER_QOS_PROFILES.xml, and
    // using a listener for events.
    auto listener = std::make_shared<SteeringCommandDataReaderListener>();

    command_reader.set_listener(listener, status_mask);

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
