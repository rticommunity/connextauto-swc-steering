# Software Component : Steering Column Demo

## Introduction

Demonstrate Sterring Column control using RTI Connext DDS.

## Dependencies

- RTI Connext Professional 7.3 LTS (SDK) for DDS

- [connextauto-bus](https://github.com/rticommunity/connextauto-bus) for common data architecture
  - **(if not done already)** Follow the [Getting Started](https://github.com/rticommunity/connextauto-bus?tab=readme-ov-file#getting-started) instructions in [connextauto-bus](https://github.com/rticommunity/connextauto-bus) repo
  - At this point, the directory structure should look like this:

        /path/to/connextauto/
            ├── connextauto-bus
   - `$DATABUSHOME` refers to `/path/to/connextauto/connextauto-bus`

- Python for Visualization (OPTIONAL)
   - Install packages
     - Linux (Ubuntu)

           apt install python3-pip python3-pil python3-pil.imagetk

      - macOS

            brew install python@3.12 pillow python-tk@3.12

  - Create and activate venv

         python3.12 -m venv .venv
         . .venv/bin/activate

  - Install python libraries in the venv

         pip install pillow

         # rti.connext (see RTI Connext Getting Started)
         pip install rti.connext.activated -f $NDDSHOME/resource/python_api

## Getting Started

- Clone (or fork and clone) this repo into the `connextauto/` directory (see [Dependencies](#dependencies))

      cd /path/to/connextauto/

      git clone <git_url_to_this_repository>

   The directory structure should look like this:

      /path/to/connextauto/
            ├── connextauto-bus
            ├── connextauto-swc-steering

- Change to the software component (swc) directory:

      cd connextauto-swc-steering/

- Build for the target architecture <arch>

      make -f makefile_<arch>

  e.g.:

  `<arch>` = x64Linux4gcc7.3.0

      make -f makefile_x64Linux4gcc7.3.0

   `<arch>` = armv8Linux4gcc7.3.0

        make -f makefile_armv8Linux4gcc7.3.0


## Run the applications


   The platform independent `makefile` provides a launcher to run the apps.
   The generic pattern for launching the apps is as follows.

      make <arch>/<app>

  e.g.
   `<arch>` = x64Linux4gcc7.3.0

      make x64Linux4gcc7.3.0/display
      make x64Linux4gcc7.3.0/controller
      make x64Linux4gcc7.3.0/actuator

   `<arch>` = armv8Linux4gcc7.3.0

      make armv8Linux4gcc7.3.0/display
      make armv8Linux4gcc7.3.0/controller
      make armv8Linux4gcc7.3.0/actuator

   `<arch>` = Python

      make py/display
      make py/controller

   You can pass enviornment variables to `make` as follows.
   The example below sets the environment variable `STEERING_CONTROLLER_STRENGTH` to 20

      make STEERING_CONTROLLER_STRENGTH=20 x64Linux4gcc7.3.0/controller

      make STEERING_CONTROLLER_STRENGTH=20 armv8Linux4gcc7.3.0/controller

      make STEERING_CONTROLLER_STRENGTH=20 py/controller


## Running on a remote target (eg Raspberry Pi)

- On Local Terminal: Package apps and config files

        make <arch>/package
    e.g.

          make armv8Linux4gcc7.3.0/package
          make x64Linux4gcc7.3.0/package

    This step creates a package `./steering_<arch>.tgz`

- Transfer the package to the remote host, e.g.:

      scp steering_<arch>.tgz user@server:/remote/path/

- On Remote Terminal: Unpack the apps and config files

      cd /remote/path
      tar zxvf steering_<arch>.tgz
      cd connextauto-swc-steering

- On Remote Terminal, [run apps as before for the target architecture](#run-the-applications)

## Overview

The demo comprises of three applications exchanging data over the RTI Connext Databus, using DDS. They use the datatypes defined in the files below.
- [$DATABUSHOME/res/types/data/actuation/Steering_t.idl](https://github.com/rticommunity/connextauto-bus/blob/master/res/types/data/actuation/Steering_t.idl)

The components are decribed below.

- **SteeringColumn**, a.k.a. the actuator, reads steering commands and writes steering status
- **SteeringController** writes steering commands
- **SteeringDisplay** takes and displays steering status

The SteeringColumn is implemented in C++. The SteeringController and SteeringDisplay components have two implementaion variants: one in C++ with a textual user interface, and another in Python with a GUI.

To browse the data architecture, including QoS, use [RTI System Designer](https://community.rti.com/static/documentation/connext-dds/current/doc/manuals/connext_dds_professional/tools/system_designer/index.html):

  -  Launch [RTI System Designer](https://community.rti.com/static/documentation/connext-dds/current/doc/manuals/connext_dds_professional/tools/system_designer/index.html)
  - Open the [`$DATABUSHOME/connextauto.rtisdproj`](https://github.com/rticommunity/connextauto-bus/blob/master/connextauto_steering.rtisdproj) project


---
(C) Copyright 2020-2025 Real-Time Innovations, Inc.  All rights reserved.

The use of this software is governed by the terms specified in the RTI Labs License Agreement, available at https://www.rti.com/terms/RTILabs. 

By accessing, downloading, or otherwise using this software, you agree to be bound by those terms.
