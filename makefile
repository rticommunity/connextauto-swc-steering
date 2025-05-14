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
    DATABUSHOME := bus
endif

# ----------------------------------------------------------------------------

help: $(TARGET_ARCH)
	@echo
	@echo Available Commands:
	@echo 'make -f makefile_<arch> : build apps for <arch>'
	@echo 'clean          : cleanup generated files'
	@echo 'bus            : sparse checkout bus submodule and generate xml types'
	@echo '<arch>/<app>   : run the app (if xml types are missing run: make bus)'
	@echo '<arch>/package : package apps and runtime for execution on another host'

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
%.dir : bus
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
	-find bus/res/types -name \*.xml -exec rm {} \;
	-rm package_*.tgz

# ----------------------------------------------------------------------------

# sparse checkout the bus submodule and generate the xml datatypes
bus: bus.sparse.enable bus.xml

# sparse checkout the bus submodule
bus.sparse.enable:
	@cd bus/ && \
	git sparse-checkout set \
		if/steering \
		res/types/data/actuation \
		res/qos/data res/qos/services/steering \
		res/env \
		bin && \
	ls -F .

# list the files from the bus submodule sparse checkout
bus.sparse.list:
	@cd bus/ && \
	git sparse-checkout list

# disable bus sparse checkout
bus.sparse.disable:
	@cd bus/ && \
	git sparse-checkout disable && \
	ls -F .

# generate the xml datatypes from the IDL types checked out in the bus submodule
bus.xml:
	${NDDSHOME}/bin/rtiddsgen -convertToXml -r -inputIDL bus/res/types

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
# Package apps and runtime for running on a remote target (eg Raspberry Pi)
#
# Local Terminal: Package apps and config files
#     make <arch>/package
#     e.g.
#	make x64Linux4gcc7.3.0/package
#	make armv8Linux4gcc7.3.0/package
#     This creates a package ./steering_<arch>.tgz
#
# Transfer the package to the remote host
#     scp package_<arch>.tgz user@server:/remote/path/
#
# Remote Terminal
#     # Unpackage apps and config files
#     cd /remote/path
#     tar zxvf package_<arch>.tgz
#
#     # run apps as before, e.g.:
#     make armv8Linux4gcc7.3.0/actuator
%/package:
	tar zcvf package_$*.tgz \
		bus/bin \
		bus/if \
		bus/res \
		img \
		*.py \
		makefile \
		objs/$*/*[^.o]
