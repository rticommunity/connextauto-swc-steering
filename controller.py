import tkinter as tk
import rti.connextdds as dds

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

# Load the QoS provider with the XML configuration
qos_provider = dds.QosProvider.default

# Create a DomainParticipant from the configuration
participant = qos_provider.create_participant_from_config(
    "SteeringColumnParticipantLibrary::PythonController"
)

# Lookup the DataWriter from the configuration
command_writer = dds.DynamicData.DataWriter(
    participant.find_datawriter("Publisher::SteeringCommandTopicWriter")
)

# Enable the participant and its underlying entities
participant.enable()

print("DomainParticipant and entities created and enabled successfully.")

# Create the main window
root = tk.Tk()
root.title("Slider Control")

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