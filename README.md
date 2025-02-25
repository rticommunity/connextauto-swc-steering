# Software Component : Steering Column Demo

## Introduction

Demonstrate Sterring Column control use case using RTI Connext DDS.

## Dependencies

- RTI Connext Professional 7.3 LTS (SDK)

- [connextauto-bus](https://github.com/rticommunity/connextauto-bus) provides the common data model, data interfaces, common build system, and component
launcher for components in the connextauto ecosystem, and it is:

  - Located at the path specified by the environment variable `$DATABUSHOME`
  - **(if not done already)** Follow the [Getting Started](https://github.com/rticommunity/connextauto-bus?tab=readme-ov-file#getting-started) instructions in the [`$DATABUSHOME/README.md`](https://github.com/rticommunity/connextauto-bus?tab=readme-ov-file#getting-started) to generate the datatypes for the *RTI Connext SDK*(s) used by this component


- Python (OPTIONAL) for Visualization

  ```bash
  sudo apt-get install python3-pil python3-pil.imagetk
  ```


## Getting Started

- Clone (or fork and clone) this repo

      git clone <a_git_url_to_this_repository>

- Build for the target $RTI_ARCH

      export RTI_ARCH=x64Linux4gcc7.3.0
      make -f makefile_$RTI_ARCH

- Run the applications using the launcher scripts
    
      # Steering Display
      make -f makefile_$RTI_ARCH display      # C++ app
      make -f makefile_$RTI_ARCH pydisplay    # python GUI

      # SteeringController
      make -f makefile_$RTI_ARCH controller   # C++ app
      make -f makefile_$RTI_ARCH pycontroller # python GUI

      # Steering Column
      make -f makefile_$RTI_ARCH actuator     # C++ app

## Overview

The demo comprises of three applications exchanging data over the RTI Connext Databus, using DDS.

- SteeringColumn
- SteeringController
- Ssteering Display

To browse and the data architecture, use [RTI System Designer](https://community.rti.com/static/documentation/connext-dds/current/doc/manuals/connext_dds_professional/tools/system_designer/index.html):

  -  Launch [RTI System Designer](https://community.rti.com/static/documentation/connext-dds/current/doc/manuals/connext_dds_professional/tools/system_designer/index.html)
  - Open the [`$DATABUSHOME/connextauto.rtisdproj`](https://github.com/rticommunity/connextauto-bus/blob/master/connextauto_steering.rtisdproj) project


---
(C) Copyright 2020-2025 Real-Time Innovations, Inc.  All rights reserved.

The use of this software is governed by the terms specified in the RTI Labs License Agreement, available at https://www.rti.com/terms/RTILabs. 

By accessing, downloading, or otherwise using this software, you agree to be bound by those terms.
