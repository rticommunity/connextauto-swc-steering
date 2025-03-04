######################################################################
# makefile
# (C) Copyright 2020-2025 Real-Time Innovations, Inc.  All rights reserved.
#
# The use of this software is governed by the terms specified in the RTI
# Labs License Agreement, available at https://www.rti.com/terms/RTILabs.
#
# By accessing, downloading, or otherwise using this software, you agree to
# be bound by those terms.
######################################################################

ifndef DATABUSHOME
    DATABUSHOME := $(shell cd ../connextauto-bus/; pwd -P)
endif

# ----------------------------------------------------------------------------
# Datatypes to build
STEERING_t     := Steering_t
IDL_DIR        := $(DATABUSHOME)/res/types/data/actuation
SOURCES = $(SOURCE_DIR)$(STEERING_t)Plugin.cxx $(SOURCE_DIR)$(STEERING_t).cxx
COMMONSOURCES = $(notdir $(SOURCES))

EXEC          = SteeringColumn_display SteeringColumn_controller SteeringColumn_actuator
DIRECTORIES   = objs.dir objs/$(TARGET_ARCH).dir
COMMONOBJS    = $(COMMONSOURCES:%.cxx=objs/$(TARGET_ARCH)/%.o)

# We actually stick the objects in a sub directory to keep your directory clean.
$(TARGET_ARCH) : $(DIRECTORIES) $(COMMONOBJS) \
	$(EXEC:%=objs/$(TARGET_ARCH)/%.o) \
	$(EXEC:%=objs/$(TARGET_ARCH)/%)

objs/$(TARGET_ARCH)/% : objs/$(TARGET_ARCH)/%.o
	$(LINKER) $(LINKER_FLAGS) -o $@ $@.o $(COMMONOBJS) $(LIBS)

objs/$(TARGET_ARCH)/%.o : $(SOURCE_DIR)%.cxx   $(SOURCE_DIR)$(STEERING_t).hpp
	$(COMPILER) $(COMPILER_FLAGS) -o $@ $(DEFINES) $(INCLUDES) -c $<

#
# Regenerate support files when idl file is modified
$(SOURCE_DIR)$(STEERING_t)Plugin.cxx $(SOURCE_DIR)$(STEERING_t).cxx \
$(SOURCE_DIR)$(STEERING_t).hpp $(SOURCE_DIR)$(STEERING_t)Plugin.hpp : \
		$(IDL_DIR)/$(STEERING_t).idl
	$(NDDSHOME)/bin/rtiddsgen $(IDL_DIR)/$(STEERING_t).idl -d . -replace -language C++11
#
# Here is how we create those subdirectories automatically.
%.dir :
	@echo "Checking directory $*"
	@if [ ! -d $* ]; then \
		echo "Making directory $*"; \
		mkdir -p $* ; \
	fi;

# ----------------------------------------------------------------------------
# Clean generated files and dirs
clean:
	-rm -rf objs
	-rm $(SOURCE_DIR)$(STEERING_t)Plugin.cxx $(SOURCE_DIR)$(STEERING_t).cxx \
	    $(SOURCE_DIR)$(STEERING_t).hpp $(SOURCE_DIR)$(STEERING_t)Plugin.hpp
	-rm steering_*.tgz

# ----------------------------------------------------------------------------
# Run the apps
#     make <arch>/<app>
# e.g.
#	make x64Linux4gcc7.3.0/display
#	make armv8Linux4gcc7.3.0/display
#
#	make py/display
#
py/display:
	$(DATABUSHOME)/bin/run Steering ./display.py

STEERING_CONTROLLER_STRENGTH ?= 2
py/controller:
	$(DATABUSHOME)/bin/run Steering ./controller.py \
		--strength $(STEERING_CONTROLLER_STRENGTH)

%/display:
	$(DATABUSHOME)/bin/run Steering ./objs/$*/SteeringColumn_display

%/controller:
	$(DATABUSHOME)/bin/run Steering ./objs/$*/SteeringColumn_controller \
		--strength $(STEERING_CONTROLLER_STRENGTH)

%/actuator:
	$(DATABUSHOME)/bin/run Steering ./objs/$*/SteeringColumn_actuator

# ----------------------------------------------------------------------------
# Running on a remote target (eg Raspberry Pi)
#
# Local Terminal: Package apps and config files
#     make <arch>/package
#     e.g.
#	make x64Linux4gcc7.3.0/package
#	make armv8Linux4gcc7.3.0/package
#     This creates a package ./steering_<arch>.tgz
#
# Transfer the package to the remote host
#     scp steering_<arch>.tgz user@server:/remote/path/
#
# Remote Terminal
#     # Unpackage apps and config files
#     cd /remote/path
#     tar zxvf steering_<arch>.tgz
#     cd connextauto-swc-steering
#
#     # run apps as before:
#     make armv8Linux4gcc7.3.0/display
%/package:
	cd .. && \
	tar zcvf steering_$*.tgz \
		connextauto-bus/bin \
		connextauto-bus/if \
		connextauto-bus/res \
		connextauto-swc-steering/img \
		connextauto-swc-steering/*.py \
		connextauto-swc-steering/makefile \
		connextauto-swc-steering/makefile_$* \
		connextauto-swc-steering/objs/$*/*[^.o]
	mv ../steering_$*.tgz .
