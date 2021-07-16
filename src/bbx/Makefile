GO := go
GOBUILD := $(GO) build

SOURCEDIR := ./cmd/
BUILDDIR := ./build/

#
# --------------------------------------
# Don't edit below this
# --------------------------------------
#

all: clean build

clean:
	rm -rf $(BUILDDIR)

build:
	$(GOBUILD) -o "$(BUILDDIR)/bbxdevd" "$(SOURCEDIR)/bbxdevd/..."
	$(GOBUILD) -o "$(BUILDDIR)/bbxwebd" "$(SOURCEDIR)/bbxwebd/..."
