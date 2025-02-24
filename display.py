import tkinter as tk
from PIL import Image, ImageTk
import rti.connextdds as dds
import time

def load_image():
    global image, tk_image, canvas
    image = Image.open("img/ford-f150-carbon-fiber-steering-wheel.jpg")
    display_image(angle)
    canvas.config(width=tk_image.width(), height=tk_image.height())
    start_rotation_loop()

def start_rotation_loop():
    for data, info in reader.take():
        if info.valid:
            display_image(data['position'])
        else:
            print("Received metadata")
    root.after(100, start_rotation_loop)  # Update every 100 milliseconds

def display_image(angle):
    global tk_image
    rotated_image = image.rotate(-angle, expand=False)
    tk_image = ImageTk.PhotoImage(rotated_image)
    canvas.create_image(0, 0, anchor=tk.NW, image=tk_image)

# Load QoS profiles from the XML configuration file
qos_provider = dds.QosProvider.default

# Create a DomainParticipant using the specified QoS profile
participant = qos_provider.create_participant_from_config(
    "SteeringColumnParticipantLibrary::PythonDisplay"
)

# Get the DataReader
reader = dds.DynamicData.DataReader(
    participant.find_datareader("Subscriber::SteeringStatusTopicReader")
)

participant.enable()

root = tk.Tk()
root.title("Steering Column Display")

canvas = tk.Canvas(root)
canvas.pack(fill=tk.BOTH, expand=True)

image = None
tk_image = None
angle = 0

load_image()

root.mainloop()