usage:
	@echo "usage: make [target...]"
	@echo "target:"
	@for app in $(apps); do echo "  $$app"; done | LC_ALL=C sort

# Install destination prefix
prefix ?= ~/app/

# Apps that can be downloaded/installed in this Makefile
apps :=

# Check required rpms installation before installation.
pre_install_require = /usr/bin/lsb_release

# Operating system
uname_os := $(shell uname -o)

ifeq ($(uname_os), GNU/Linux)
os := linux
else ifeq ($(uname_os), Msys)
os := windows
else
os := $(uname_os)
endif

# JDK
apps += jdk
jdk_version := 17
jdk_package := jdk-$(jdk_version)_$(os)-x64_bin.tar.gz
jdk: $(jdk_package)
$(jdk_package):
	wget -c https://download.oracle.com/java/$(jdk_version)/latest/$@


# JRuby
apps += jruby
jruby_version := 9.4.4.0
jruby_package := jruby-dist-$(jruby_version)-bin.tar.gz
jruby: $(jruby_package)
$(jruby_package):
	wget -c https://repo1.maven.org/maven2/org/jruby/jruby-dist/$(jruby_version)/$@


# JRuby-Complete
apps += jruby_complete
jruby_complete_version := $(jruby_version)
jruby_complete_package := jruby-complete-$(jruby_complete_version).jar
jruby_complete: $(jruby_complete_package)
$(jruby_complete_package):
	wget -c https://repo1.maven.org/maven2/org/jruby/jruby-complete/$(jruby_complete_version)/$@


# Maven
apps += maven
maven_version := 3.9.5
maven_package := apache-maven-$(maven_version)-bin.tar.gz
maven: $(maven_package)
$(maven_package):
	wget -c https://dlcdn.apache.org/maven/maven-3/$(maven_version)/binaries/$@

# Maven-package
apps += maven-rpm
maven_arch := noarch
maven_rpm: apache-maven-$(maven_version).$(maven_arch).rpm
$(maven_rpm): $(maven_package) $(fpm)
	$(fpm) -s tar -t rpm -n apache-maven -a $(maven_arch) --prefix $(prefix) $<

# Warbler
apps += warbler
warbler_version := 2.0.5
warbler_package := warbler-$(warbler_version).tar.gz

warbler: $(warbler_package)
$(warbler_package):
	wget -c -O $@ https://github.com/jruby/warbler/archive/refs/tags/v$(warbler_version).tar.gz


# Golang
apps += golang
golang_version := 1.21.3
golang_package := go$(golang_version).linux-amd64.tar.gz
golang: $(golang_package)
$(golang_package):
	wget -c -O $@ https://go.dev/dl/$@


# Graalvm
apps += graalvm
graalvm_version := 17
graalvm_package := graalvm-jdk-$(graalvm_version)_linux-x64_bin.tar.gz

graalvm: $(graalvm_package)
$(graalvm_package):
	wget -c -O $@ https://download.oracle.com/graalvm/17/latest/$@


# Graalvm-package
apps += graalvm-rpm
graalvm_arch := x86_64
graalvm_rpm := apache-graalvm-$(graalvm_version).$(graalvm_arch).rpm
graalvm-rpm: $(graalvm_rpm)
$(graalvm_rpm): $(graalvm_package) $(fpm)
	$(fpm) -s tar -t rpm -n graalvm-jdk -a $(graalvm_arch) --prefix $(prefix) $<

# leininage
apps += leiningen
leiningen: lein.zip
lein.zip:
	wget -c https://raw.githubusercontent.com/technomancy/leiningen/stable/bin/lein
	chmod +x lein
	zip --move --test $@ lein


# TruffleRuby
apps += truffleruby
truffleruby_version := 23.1.1
truffleruby_package := truffleruby-$(truffleruby_version)-linux-amd64.tar.gz
truffleruby: $(truffleruby_package)
$(truffleruby_package):
	wget -c -O $@ https://github.com/oracle/truffleruby/releases/download/graal-$(truffleruby_version)/$(truffleruby_package)

apps += truffleruby-install
truffleruby_dir := $(prefix)$(patsubst %.tar.gz,%,$(truffleruby_package))/
truffleruby_bin := $(truffleruby_dir)bin/truffleruby
truffleruby_ref := https://www.graalvm.org/latest/reference-manual/ruby/RubyManagers/#using-truffleruby-without-a-ruby-manager
$(truffleruby_bin): $(truffleruby_package)
	tar -xzmf $(truffleruby_package) -C $(prefix)

truffleruby_deps := $(truffleruby_dir)src/main/c/openssl/openssl.so $(truffleruby_dir)src/main/c/psych/psych.so
$(truffleruby_deps):
	distrib=$$(lsb_release -i | cut -f2); \
	case "$$distrib" in \
	    RedHatEnterpriseServer) repo='codeready-rebuilder*';; \
	    CentOSStream) repo=powertools;; \
	    *) repo='*';; \
	esac; \
	set -ex; for p in openssl-devel libyaml-devel zlib-devel gcc; do \
	    rpm -q $$p &>/dev/null || sudo dnf -y install --enablerepo="$$repo" $$p; done;
	cd $(truffleruby_dir) && lib/truffle/post_install_hook.sh
	@test -z "$${GEM_HOME}" || echo -e "** Please unset environment variable \e[31mGEM_HOME\e[0m, see $(truffleruby_ref)"
	@test -z "$${GEM_PATH}" || echo -e "** Please unset environment variable \e[31mGEM_PATH\e[0m, see $(truffleruby_ref)"

truffleruby-install: $(pre_install_require) $(truffleruby_bin) $(truffleruby_deps)

# fpm for unpacking rpm files
apps += fpm-install
fpm := $(truffleruby_dir)/bin/fpm
fpm-install : $(fpm)
$(fpm): $(truffleruby_bin)
	$(truffleruby_bin) -S gem install fpm

# Bitwarden Cli
apps += bitwarden
bitwarden: bw
bw: bw.zip
	unzip $<
bw.zip:
	wget -c -O $@ 'https://vault.bitwarden.com/download/?app=cli&platform=linux'


# Babashka
apps += babashka
babashka_version := 1.3.188
ifeq ($(os), linux)
babashka_package := babashka-$(babashka_version)-$(os)-amd64-static.tar.gz
else ifeq ($(os), windows)
babashka_package := babashka-$(babashka_version)-$(os)-amd64.zip
endif

babashka: $(babashka_package)
$(babashka_package):
	wget -c -O $@ https://github.com/babashka/babashka/releases/download/v$(babashka_version)/$(babashka_package)

apps += babashka-install
ifeq ($(wildcard ~/bin/.),)
babashka_bindir := $(prefix)babashka-$(babashka_version)/bin
else
babashka_bindir := ~/bin
endif
babashka-install: $(babashka_package)
	mkdir -p $(babashka_bindir)
	[[ $^ == *.zip ]] && unzip $^ -d $(babashka_bindir) || tar xaf $(babashka_package) -C $(babashka_bindir)

# JASSPA MicroEmacs
apps += jasspa_2009
jasspa_version := 20091011
jasspa_package := jasspa-mesrc-$(jasspa_version).tar.gz

jasspa_2009: $(jasspa_package)
$(jasspa_package):
	wget -c -O $@.swp http://www.jasspa.com/release_20090909/$(jasspa_package)
	mv -f $@.swp $@

apps += jasspa_2009-install
ifeq ($(wildcard ~/bin/.),)
jasspa_bindir := $(prefix)jasspa-$(babashka_version)/bin
else
jasspa_bindir := ~/bin
endif
jasspa_2009-install: $(jasspa_bindir)/mec2009
$(jasspa_bindir)/mec2009: builddir := $(shell mktemp -d --suffix=.jasspa)
$(jasspa_bindir)/mec2009: $(jasspa_package)
	tar -xaf $(jasspa_package) -C $(builddir) --strip-components=2
	cd $(builddir)/src && sed -i -e 's/sys_errlist\[errno]/strerror(errno)/g' *.c
	cd $(builddir)/src && ./build && cp -f mec $@
	rm -rf $(builddir)

# JASSPA MicroEmacs from github
apps += jasspa
jasspa_version := 09.12.21
jasspa_package := jasspa-mesrc-$(jasspa_version).tar.gz

jasspa: $(jasspa_package)
$(jasspa_package):
	wget -c -O $@.swp https://github.com/mittelmark/microemacs/archive/refs/tags/v$(jasspa_version).tar.gz
	mv -f $@.swp $@

apps += jasspa-install
ifeq ($(wildcard ~/bin/.),)
jasspa_bindir := $(prefix)jasspa-$(babashka_version)/bin
else
jasspa_bindir := ~/bin
endif

ifneq ($(MSYSTEM),)
exe=.exe
endif

jasspa-install: $(jasspa_bindir)/mec$(exe)
$(jasspa_bindir)/mec$(exe): builddir := $(shell mktemp -d --suffix=.jasspa)
$(jasspa_bindir)/mec$(exe): $(jasspa_package)
	tar -xaf $(jasspa_package) -C $(builddir) --strip-components=1
	patch -d $(builddir) -p0 < jasspa.patch
	cd $(builddir) && rm -f bin/me* bin/bfs*
	cd $(builddir)/src && ./build
	cd $(builddir) && make me-bfs-bin
	[ -f $(builddir)/bin/mec-linux.bin ] &&  cp $(builddir)/bin/mec-linux.bin $@ ||:
	[ -f $(builddir)/bin/mec-windows.exe ] && cp $(builddir)/bin/mec-windows.exe $@ ||:
	test -f $@
	-cp -f $(builddir)/bin/bfs* $(@D)
	rm -rf $(builddir)

/usr/bin/lsb_release:
	sudo dnf -y install redhat-lsb-core

apps += phcl-microemacs
phcl-microemacs_pkg := $(patsubst %,phcl-microemacs/%, MicroEmacs-4.21-0.0.src.rpm MicroEmacs-4.21-0.0.x86_64.rpm)
phcl-microemacs: $(phcl-microemacs_pkg)
$(phcl-microemacs_pkg):
	mkdir -p $(@D)
	rsync -Pt rsync://www.phcomp.co.uk/downloads/centos9-x86_64/phcl/$(@F) $(@D)/

# All
all: $(apps)
