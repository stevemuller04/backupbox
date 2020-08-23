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
	$(GOBUILD) -o "$(BUILDDIR)/bbxd" "$(SOURCEDIR)/bbxd/..."
	$(GOBUILD) -o "$(BUILDDIR)/bbxweb" "$(SOURCEDIR)/bbxweb/..."
