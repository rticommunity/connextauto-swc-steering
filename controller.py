#!/usr/bin/env python3
import tkinter as tk
import rti.connextdds as dds
import argparse

# Define the SteeringCommand type as a DynamicData type
steering_command_type = dds.StructType(
    "SteeringCommand",
    [
        dds.Member("position", dds.Float32Type()),
        dds.Member("speed", dds.Float32Type())
    ]
)

# Function to update the label with the slider value
def update_value(val):
    steering_command_data = dds.DynamicData(steering_command_type)
    value = int(val)
    steering_command_data["position"] = value
    label.config(text=f"Value: {value}")
    command_writer.write(steering_command_data)

# Parse command-line arguments
parser = argparse.ArgumentParser(description="Steering Column Controller")
parser.add_argument("--strength", default=0, help="Strength of the steering command DataWriter")
args = parser.parse_args()

# Load the QoS provider with the XML configuration
qos_provider = dds.QosProvider.default

# Create a DomainParticipant from the configuration
participant = qos_provider.create_participant_from_config(
    "DriveParticipantLib::SteeringController"
)

# Lookup the DataWriter from the configuration
command_writer = dds.DynamicData.DataWriter(
    participant.find_datawriter("outputs::Steering_writer")
)

# Set DataWriter Strength
command_writer_qos = command_writer.qos
command_writer_qos.ownership_strength.value = int(args.strength)
command_writer.qos = command_writer_qos

# Enable the participant and its underlying entities
participant.enable()

print("DomainParticipant and entities created and enabled successfully.")

# Create the main window
root = tk.Tk()
root.title(f"Slider Control : Strength = {command_writer.qos.ownership_strength.value}")

# Set the size of the window
root.geometry("600x150")

# Set up the slider
slider = tk.Scale(root, from_=-180, to=180, orient="horizontal", command=update_value, length=500, width=30)
slider.pack(pady=20)

# Label to display the selected value
label = tk.Label(root, text="Value: 0")
label.pack()

update_value(0)

# Run the application
root.mainloop()
