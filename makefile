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
    #DATABUSHOME := ../connextauto-bus
endif

# ----------------------------------------------------------------------------

help: $(TARGET_ARCH)
	@echo Available Commands:
	@echo ------------------
	@echo 'init         : initialize, update, and checkout submodules (idempotent)'
	@echo '               (execute after every "make update" or "git clone")'
	@echo '<arch>/build : build all apps for <arch>'
	@echo '<arch>/<app> : run the <app> for <arch>'
	@echo '<arch>/swc   : package apps and runtime for execution on another host'
	@echo 'clean        : cleanup generated files'
	@echo
	@echo 'update       : update bus submodule to latest commit in remote tracking branch'
	@echo
	@echo 'where'
	@echo '   arch =  <arch> (Any RTI Connext Supported Platform) | py (Python) '
	@echo '   app  = actuator | controller | display'

# ----------------------------------------------------------------------------
# Datatypes to build
CDRSOURCES    := $(DATABUSHOME)/res/types/data/actuation/Steering_t.idl
SOURCES       := $(CDRSOURCES:.idl=.cxx) $(CDRSOURCES:.idl=Plugin.cxx)
COMMONSOURCES := $(notdir $(SOURCES))

# Apps to build
EXEC          = SteeringDisplay SteeringController SteeringColumn
DIRECTORIES   = objs.dir objs/$(TARGET_ARCH).dir
COMMONOBJS    = $(COMMONSOURCES:%.cxx=objs/$(TARGET_ARCH)/%.o)

# ----------------------------------------------------------------------------
# Build rules

# Directory to hold generated type support files:
GEN_DIR        := objs/gen/cxx

# Generated headers and files
GEN_HEADERS := $(addprefix $(GEN_DIR)/, $(COMMONSOURCES:.cxx=.hpp))
GEN_FILES   := $(addprefix $(GEN_DIR)/, $(COMMONSOURCES)) $(GEN_HEADERS)

# INCLUDES: Tell Compiler where to seach for generated include header files
INCLUDES    += -I$(GEN_DIR)

# VPATH: Tell Make where to search for prerequisites (source files).
# This adds all unique directories from your sources list to the search path.
VPATH       := $(sort $(GEN_DIR) $(SOURCE_DIR))


# We actually stick the objects in a sub directory to keep your directory clean.
$(TARGET_ARCH) : $(DIRECTORIES) $(COMMONOBJS) \
	$(EXEC:%=objs/$(TARGET_ARCH)/%.o) \
	$(EXEC:%=objs/$(TARGET_ARCH)/%)

objs/$(TARGET_ARCH)/% : objs/$(TARGET_ARCH)/%.o
	$(LINKER) $(LINKER_FLAGS) -o $@ $@.o $(COMMONOBJS) $(LIBS)

objs/$(TARGET_ARCH)/%.o : %.cxx $(GEN_HEADERS)
	$(COMPILER) $(COMPILER_FLAGS) -o $@ $(DEFINES) $(INCLUDES) -c $<

#
# Regenerate support files when idl file is modified
$(GEN_FILES) : $(CDRSOURCES)
	$(NDDSHOME)/bin/rtiddsgen $(CDRSOURCES) -d $(GEN_DIR) -replace -language C++11

$(CDRSOURCES:.idl=.xml):
	$(NDDSHOME)/bin/rtiddsgen -convertToXml -r -inputIDL $(DATABUSHOME)/res/types

# generate the xml datatypes from the IDL types checked out in the bus submodule
types.xml: $(CDRSOURCES:.idl=.xml)

# Here is how we create those subdirectories automatically.
%.dir :
	@echo "Checking directory $*"
	@if [ ! -d $* ]; then \
		echo "Making directory $*"; \
		mkdir -p $* ; \
	fi;

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

# ----------------------------------------------------------------------------
# build apps for <arch>
%/build : $(GEN_DIR).dir
	make -f makefile_$* $*

# ----------------------------------------------------------------------------
# Clean generated files and dirs
clean:
	-rm -rf objs
	-find $(DATABUSHOME)/res/types -name \*.xml -exec rm {} \;
	-rm swc_*.tgz

# ----------------------------------------------------------------------------
# Run the apps
#     make <arch>/<app>
# e.g.
#	make x64Linux4gcc7.3.0/display
#	make armv8Linux4gcc7.3.0/display
#
#	make py/display
#
py/display: types.xml
	$(DATABUSHOME)/bin/run Steering ./SteeringDisplay.py

STRENGTH ?= 2
py/controller: types.xml
	$(DATABUSHOME)/bin/run Steering ./SteeringController.py \
		--strength $(STRENGTH)

%/display: types.xml
	$(DATABUSHOME)/bin/run Steering ./objs/$*/SteeringDisplay

%/controller: types.xml
	$(DATABUSHOME)/bin/run Steering ./objs/$*/SteeringController \
		--strength $(STRENGTH)

%/actuator: types.xml
	$(DATABUSHOME)/bin/run Steering ./objs/$*/SteeringColumn

# ----------------------------------------------------------------------------
# bus submodule (common data architecture)

# sparse checkout the bus submodule
bus.sparse.enable: submodule.init bus.sparse.disable
	@cd bus/ && \
	git sparse-checkout set \
		if/steering \
		res/types/data/actuation \
		res/qos/data \
		res/qos/services/steering \
		res/env \
		bin && \
	ls -F .

# sparse checkout the bus submodule: just the relevant files
bus.sparse.enable.nocone: submodule.init bus.sparse.disable
	@cd bus/ && \
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
	@cd bus/ && \
	git sparse-checkout disable

# list the files from the bus submodule sparse checkout
bus.sparse.ls:
	@cd bus/ && \
	git sparse-checkout list

# ----------------------------------------------------------------------------
# submodules

# initialize and update all submodules
submodule.init:
	git submodule update --init

# bus submodule: update to the latest commit in remote tracking branch ("master")
update:
	git submodule update --remote bus

# initialize and update all submodules, and checkout bus submodule (sparse-checkout)
init: submodule.init \
      bus.sparse.enable.nocone

# ----------------------------------------------------------------------------
