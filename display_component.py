import tkinter as tk
from tkinter import filedialog
from PIL import Image, ImageTk

class ImageRotatorApp:
    def __init__(self, root):
        self.root = root
        self.root.title("Image Rotator")
        
        self.canvas = tk.Canvas(root)
        self.canvas.pack(fill=tk.BOTH, expand=True)
        
        self.load_button = tk.Button(root, text="Load Image", command=self.load_image)
        self.load_button.pack()
        
        self.rotate_button = tk.Button(root, text="Rotate", command=self.rotate_image)
        self.rotate_button.pack()
        
        self.image = None
        self.tk_image = None
        self.angle = 0
    
    def load_image(self):
            self.image = Image.open("img/ford-f150-carbon-fiber-steering-wheel.jpg")
            self.angle = 0  # Reset angle when a new image is loaded
            self.display_image()
    
    def rotate_image(self):
        if self.image:
            self.angle = (self.angle + 90) % 360  # Rotate in 90-degree increments
            self.display_image()
    
    def display_image(self):
        rotated_image = self.image.rotate(self.angle, expand=True)
        self.tk_image = ImageTk.PhotoImage(rotated_image)
        self.canvas.config(width=self.tk_image.width(), height=self.tk_image.height())
        self.canvas.create_image(0, 0, anchor=tk.NW, image=self.tk_image)

if __name__ == "__main__":
    root = tk.Tk()
    app = ImageRotatorApp(root)
    root.mainloop()