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

# If undefined in the environment default NDDSHOME to install dir
ifndef NDDSHOME
    NDDSHOME := "/opt/rti.com/rti_connext_dds-7.3.0"
endif
ifndef DATABUSHOME
    DATABUSHOME := bus
endif

# ----------------------------------------------------------------------------

help: $(TARGET_ARCH)
	@echo Available Commands:
	@echo ------------------
	@echo 'init           : initialize, update, and checkout submodules'
	@echo '<arch>/build   : build all apps for <arch>'
	@echo '<arch>/<app>   : run the <app> for <arch>'
	@echo '<arch>/swc     : package apps and runtime for execution on another host'
	@echo 'clean          : cleanup generated files'
	@echo 'bus            : sparse checkout bus submodule and generate xml types'
	@echo
	@echo 'where'
	@echo '   arch =  <arch> (Any RTI Connext Supported Platform) | py (Python) '
	@echo '   app  = actuator | controller | display'

# ----------------------------------------------------------------------------
# initialize, update, and checkout submodules

init: submodule.update bus

submodule.update:
	git submodule update --init

# ----------------------------------------------------------------------------
# build apps for <arch>'
%/build :
	make -f makefile_$*

# ----------------------------------------------------------------------------
# Datatypes to build
STEERING_t     := Steering_t
IDL_DIR        := $(DATABUSHOME)/res/types/data/actuation
SOURCES = $(SOURCE_DIR)$(STEERING_t)Plugin.cxx $(SOURCE_DIR)$(STEERING_t).cxx
COMMONSOURCES = $(notdir $(SOURCES))

# Apps to build
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
	-find $(DATABUSHOME)/res/types -name \*.xml -exec rm {} \;
	-rm swc_*.tgz

# ----------------------------------------------------------------------------
# bus submodule (common data architecture)

# sparse checkout the bus submodule and generate the xml datatypes
bus: bus.sparse.enable.nocone bus.xml

# sparse checkout the bus submodule
bus.sparse.enable: bus.sparse.disable
	@cd $(DATABUSHOME)/ && \
	git sparse-checkout set \
		if/steering \
		res/types/data/actuation \
		res/qos/data \
		res/qos/services/steering \
		res/env \
		bin && \
	ls -F .

# sparse checkout the bus submodule: just the relevant files
bus.sparse.enable.nocone: bus.sparse.disable
	@cd $(DATABUSHOME)/ && \
	git sparse-checkout set --no-cone \
		/if/steering \
		/res/types/data/actuation/Steering_t.idl \
		/res/qos/data/snippets \
		/res/qos/data/Flow_qos.xml /res/qos/data/Participant_qos.xml \
		/res/qos/services/Domain_qos.xml \
		/res/qos/services/steering \
		/res/env/QOS_PROVIDER.sh \
		/res/env/Steering.sh \
		/bin/run \
		/connextauto_steering.rtisdproj && \
	ls -F .

# disable bus sparse checkout
bus.sparse.disable:
	@cd $(DATABUSHOME)/ && \
	git sparse-checkout disable

# list the files from the bus submodule sparse checkout
bus.sparse.ls:
	@cd $(DATABUSHOME)/ && \
	git sparse-checkout list

# generate the xml datatypes from the IDL types checked out in the bus submodule
bus.xml:
	$(NDDSHOME)/bin/rtiddsgen -convertToXml -r -inputIDL $(DATABUSHOME)/res/types

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

STRENGTH ?= 2
py/controller:
	$(DATABUSHOME)/bin/run Steering ./controller.py \
		--strength $(STRENGTH)

%/display:
	$(DATABUSHOME)/bin/run Steering ./objs/$*/SteeringColumn_display

%/controller:
	$(DATABUSHOME)/bin/run Steering ./objs/$*/SteeringColumn_controller \
		--strength $(STRENGTH)

%/actuator:
	$(DATABUSHOME)/bin/run Steering ./objs/$*/SteeringColumn_actuator

# ----------------------------------------------------------------------------
# Package apps and runtime for running on a remote target (eg Raspberry Pi)
#
# Local Terminal: Package apps and config files
#     make <arch>/swc
#     e.g.
#	make x64Linux4gcc7.3.0/swc
#	make armv8Linux4gcc7.3.0/swc
#     This creates a package ./swc_<arch>.tgz
#
# Transfer the package to the remote host
#     scp swc_<arch>.tgz user@server:/remote/path/
#
# Remote Terminal
#     # Unpackage apps and config files
#     cd /remote/path
#     tar zxvf swc_<arch>.tgz
#
#     # run apps as before, e.g.:
#     make armv8Linux4gcc7.3.0/actuator
%/swc: %/build
	tar zcvf swc_$*.tgz \
		$(DATABUSHOME)/bin \
		$(DATABUSHOME)/if \
		$(DATABUSHOME)/res \
		img \
		*.py \
		makefile \
		objs/$*/*[^.o]
