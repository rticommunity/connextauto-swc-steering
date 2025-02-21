# Software Component : Steering Column Demo

## Introduction

Demonstrate Sterring Column control use case using RTI Connext DDS.

## Dependencies

- Python

  ```bash
  sudo apt-get install python3-pil python3-pil.imagetk
  ```

- RTI Connext Professional 7.3 LTS

- [connextauto-bus](https://github.com/rticommunity/connextauto-bus) provides the common data model, data interfaces, common build system, and component
launcher for components in the connextauto ecosystem, and it is:

  - Located at the path specified by the environment variable `$DATABUSHOME`
  - **(if not done already)** Follow the [Getting Started](https://github.com/rticommunity/connextauto-bus?tab=readme-ov-file#getting-started) instructions in the [`$DATABUSHOME/README.md`](https://github.com/rticommunity/connextauto-bus?tab=readme-ov-file#getting-started) to generate the datatypes for the *RTI Connext SDK*(s) used by this component



## Getting Started

- Clone (or fork and clone) this repo

      git clone <a_git_url_to_this_repository>

- Run the applications using the launcher scripts

      $DATABUSHOME/bin/run Steering <./path/to/app>
    
  For documentation on the `$DATABUSHOME/bin/run` launcher utility, please refer to the documentation located at [`$DATABUSHOME/doc/Run.md`](https://github.com/rticommunity/connextauto-bus/blob/develop/doc/Run.md).


## Component Overview

The demo comprises of three applications exchanging data over the RTI Connext Databus, using DDS.

- SteeringColumn
- SteeringController
- Ssteering Display


---
(C) Copyright 2020-2025 Real-Time Innovations, Inc.  All rights reserved.

The use of this software is governed by the terms specified in the RTI Labs License Agreement, available at https://www.rti.com/terms/RTILabs. 

By accessing, downloading, or otherwise using this software, you agree to be bound by those terms.
