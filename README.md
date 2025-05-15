# Software Component : Steering Column Demo

## Introduction

Demonstrate Steering Column control using RTI Connext DDS.

## Dependencies


- [OPTIONAL] Python for Visualization
   - Install packages
     - Linux (Ubuntu)

           apt install python3-pip python3-pil python3-pil.imagetk

      - macOS

            brew install python@3.12 pillow python-tk@3.12

  - Create and activate venv

         python3.12 -m venv ~/.venv
         . ~/.venv/bin/activate

  - Install python libraries in the venv

         pip install pillow

         # rti.connext (see RTI Connext Getting Started)
         pip install rti.connext.activated -f $NDDSHOME/resource/python_api


## Getting Started

- Clone (or fork and clone) this repo, e.g.

      git clone git@github.com:rticommunity/connextauto-swc-steering.git

- Change working directory to the local clone of this repo

      cd connextauto-swc-steering/

- Build for a target architecture `<arch>`

      make -f makefile_<arch>

  e.g.:
  | `<arch>`             | command
  | ---------------------|--------------------------------------
  | x64Linux4gcc7.3.0    | make -f makefile_x64Linux4gcc7.3.0
  | armv8Linux4gcc7.3.0  | make -f makefile_armv8Linux4gcc7.3.0
  | x64Darwin20clang12.0 | make -f makefile_x64Darwin20clang12.0

- Run `make` to see the list of available commands

      make


## Run the applications


   The platform independent `makefile` provides a launcher to run the apps.
   The generic pattern for launching the apps is as follows.

      make <arch>/<app>

  e.g.:
  | `<app>`    |`<arch>`              | command
  | -----------|----------------------|---------------------------------
  | actuator   | x64Linux4gcc7.3.0    | make x64Linux4gcc7.3.0/actuator
  |            | armv8Linux4gcc7.3.0  | make armv8Linux4gcc7.3.0/actuator
  |            | x64Darwin20clang12.0 | make x64Darwin20clang12.0/actuator
  | controller | x64Linux4gcc7.3.0    | make x64Linux4gcc7.3.0/controller
  |            | armv8Linux4gcc7.3.0  | make armv8Linux4gcc7.3.0/controller
  |            | x64Darwin20clang12.0 | make x64Darwin20clang12.0/controller
  |            | py (Python)          | make py/controller
  | display    | x64Linux4gcc7.3.0    | make x64Linux4gcc7.3.0/display
  |            | armv8Linux4gcc7.3.0  | make armv8Linux4gcc7.3.0/display
  |            | x64Darwin20clang12.0 | make x64Darwin20clang12.0/display
  |            | py (Python)          | make py/display


   You can pass enviornment variables to `make` as follows.
   The example below sets the environment variable `STEERING_CONTROLLER_STRENGTH` to 20

    make STEERING_CONTROLLER_STRENGTH=20 x64Linux4gcc7.3.0/controller

    make STEERING_CONTROLLER_STRENGTH=20 armv8Linux4gcc7.3.0/controller

    make STEERING_CONTROLLER_STRENGTH=20 x64Darwin20clang12.0/controller

    make STEERING_CONTROLLER_STRENGTH=20 py/controller


## Running on a remote target (e.g. Raspberry Pi)

- On Local Terminal: Package apps and config files

        make <arch>/package

  e.g.:
  | `<arch>`             | command
  | ---------------------|--------------------------------------
  | x64Linux4gcc7.3.0    | make x64Linux4gcc7.3.0/package
  | armv8Linux4gcc7.3.0  | make armv8Linux4gcc7.3.0/package
  | x64Darwin20clang12.0 | make x64Darwin20clang12.0/package

  This step creates a compressed tar package: `package_<arch>.tgz`

- Transfer the package to the remote host, e.g.:

      scp package_<arch>.tgz user@server:/remote/path/

- On Remote Terminal: Unpack the apps and config files

      cd /remote/path
      tar zxvf package_<arch>.tgz

- On Remote Terminal, [run apps as before for the target architecture](#run-the-applications)

## Data Architecture

The demo comprises of three applications exchanging data over the RTI Connext Databus, using DDS. They use the datatypes defined in the files below.
- [bus/res/types/data/actuation/Steering_t.idl](bus/res/types/data/actuation/Steering_t.idl)

The Quality of Service (QoS) profiles are defined in the files below.

- [bus/res/qos/services/steering/](bus/res/qos/services/steering)

The data interfaces are defined in the files below.

- [bus/if/steering/](bus/if/steering)

You can browse the data architecture using [RTI System Designer](https://community.rti.com/static/documentation/connext-dds/current/doc/manuals/connext_dds_professional/tools/system_designer/index.html):

  -  Launch **RTI System Designer**
  - Open the [bus/connextauto.rtisdproj](bus/connextauto_steering.rtisdproj) project
  - Browse the datatypes, qos profiles, data domains, and participant data interfaces

## Component Applications

The component applications are decribed below.

- **SteeringColumn**, a.k.a. the actuator, reads steering commands and writes steering status
  - [SteeringColumn_actuator.cxx](SteeringColumn_actuator.cxx)
- **SteeringController** writes steering commands
  - [SteeringColumn_controller.cxx](SteeringColumn_controller.cxx)
  - [controller.py](controller.py)
- **SteeringDisplay** takes and displays steering status
  - [SteeringColumn_display.cxx](SteeringColumn_display.cxx)
  - [display.py](display.py)

The SteeringColumn is implemented in C++. The SteeringController and SteeringDisplay components have two implementaion variants: one in C++ with a textual user interface, and another in Python with a GUI.

---
(C) Copyright 2020-2025 Real-Time Innovations, Inc.  All rights reserved.

The use of this software is governed by the terms specified in the RTI Labs License Agreement, available at https://www.rti.com/terms/RTILabs. 

By accessing, downloading, or otherwise using this software, you agree to be bound by those terms.
