usage:
	@echo "usage: make [target...]"
	@echo "target:"
	@for app in $(apps); do echo "  $$app"; done | LC_ALL=C sort --version-sort

# Install destination prefix
DESTDIR ?= ~/app

# Apps that can be downloaded/installed in this Makefile
apps :=

# Operating system
uname_os := $(shell uname -o)

ifeq ($(uname_os), GNU/Linux)
os := linux
req_progs := /usr/bin/lsb_release
ext := tar.gz
else ifeq ($(uname_os), Msys)
os := windows
ext := zip
else
os := $(uname_os)
ext := tar.gz
endif

# Prepare before installation
pre_install: .pre_install.done $(req_progs)

.pre_install.done:
	mkdir -p $(DESTDIR)
	mkdir -p ~/bin
	@touch $@

# Check required rpms installation before installation.
/usr/bin/lsb_release:
	sudo dnf -y install redhat-lsb-core


# JDK
apps += openlogic_jdk8
openlogic_jdk8_version := 8u422-b05
openlogic_jdk8_package := openlogic-openjdk-$(openlogic_jdk8_version)-$(os)-x64.$(ext)
openlogic_jdk8: $(openlogic_jdk8_package)
$(openlogic_jdk8_package):
	wget -c https://builds.openlogic.com/downloadJDK/openlogic-openjdk/$(openlogic_jdk8_version)/$@

apps += openlogic_jdk11
openlogic_jdk11_version := 11.0.24+8
openlogic_jdk11_package := openlogic-openjdk-$(openlogic_jdk11_version)-$(os)-x64.$(ext)
openlogic_jdk11: $(openlogic_jdk11_package)
$(openlogic_jdk11_package):
	wget -c https://builds.openlogic.com/downloadJDK/openlogic-openjdk/$(openlogic_jdk11_version)/$@

apps += openlogic_jdk17
openlogic_jdk17_version := 17.0.12+7
openlogic_jdk17_package := openlogic-openjdk-$(openlogic_jdk17_version)-$(os)-x64.$(ext)
openlogic_jdk17: $(openlogic_jdk17_package)
$(openlogic_jdk17_package):
	wget -c https://builds.openlogic.com/downloadJDK/openlogic-openjdk/$(openlogic_jdk17_version)/$@

apps += openlogic_jdk21
openlogic_jdk21_version := 21.0.4+7
openlogic_jdk21_package := openlogic-openjdk-$(openlogic_jdk21_version)-$(os)-x64.$(ext)
openlogic_jdk21: $(openlogic_jdk21_package)
$(openlogic_jdk21_package):
	wget -c https://builds.openlogic.com/downloadJDK/openlogic-openjdk/$(openlogic_jdk21_version)/$@


# Clojure
apps += clojure-install
clojure-install: pre_install
	curl -L -O https://github.com/clojure/brew-install/releases/latest/download/linux-install.sh
	chmod +x linux-install.sh
	./linux-install.sh --prefix $(DESTDIR)/clojure


# JRuby https://repo1.maven.org/maven2/org/jruby/jruby-dist/
apps += jruby
jruby_version := 9.4.8.0
jruby_package := jruby-dist-$(jruby_version)-bin.tar.gz
jruby: $(jruby_package)
$(jruby_package):
	wget -c https://repo1.maven.org/maven2/org/jruby/jruby-dist/$(jruby_version)/$@

# JRuby installation
apps += jruby-install
jruby-install: $(DESTDIR)/jruby-$(jruby_version)/lib/jruby.jar pre_install
$(DESTDIR)/jruby-$(jruby_version)/lib/jruby.jar: $(jruby_package)
	tar -xamf $< -C $(DESTDIR)

# JRuby-Complete
apps += jruby_complete
jruby_complete_version := $(jruby_version)
jruby_complete_package := jruby-complete-$(jruby_complete_version).jar
jruby_complete: $(jruby_complete_package)
$(jruby_complete_package):
	wget -c https://repo1.maven.org/maven2/org/jruby/jruby-complete/$(jruby_complete_version)/$@


# JRuby_Complete installation
apps += jruby_complete-install
jruby_complete-install: ~/bin/$(jruby_complete_package) pre_install
~/bin/$(jruby_complete_package): $(jruby_complete_package)
	cp -f $< $@


# Maven
apps += maven
maven_version := 3.9.9
maven_package := apache-maven-$(maven_version)-bin.$(ext)
maven: $(maven_package)
$(maven_package):
	wget -c https://dlcdn.apache.org/maven/maven-3/$(maven_version)/binaries/$@

# Maven-package
apps += maven-rpm
maven_arch := noarch
maven_rpm: apache-maven-$(maven_version).$(maven_arch).rpm
$(maven_rpm): $(maven_package) $(fpm)
	$(fpm) -s tar -t rpm -n apache-maven -a $(maven_arch) --prefix $(DESTDIR) $<


# Warbler
apps += warbler
warbler_version := 2.0.5
warbler_package := warbler-$(warbler_version).tar.gz
warbler: $(warbler_package)
$(warbler_package):
	wget -c -O $@ https://github.com/jruby/warbler/archive/refs/tags/v$(warbler_version).tar.gz


# TinyGo https://github.com/tinygo-org/tinygo/releases
apps += tinygo
tinygo_version := 0.31.2
ifeq ($(MSYSTEM),MSYS)
tinygo_package := tinygo$(tinygo_version).windows-amd64.zip
else
tinygo_package := tinygo(golang_version).linux-amd64.tar.gz
endif

tinygo: $(tinygo_package)
$(tinygo_package):
	wget -c -O $@ https://github.com/tinygo-org/tinygo/releases/download/v$(tinygo_version)/$@

# TinyGo-install
apps += tinygo-install
tinygo-install: $(DESTDIR)/tinygo/lib/musl/COPYRIGHT pre_install
$(DESTDIR)/tinygo/lib/musl/COPYRIGHT: $(tinygo_package)
	mkdir -p $(DESTDIR)
	case "$<" in *.zip) unzip -DD -n -d $(DESTDIR) $<;; *.tar.*) tar -xamf $< -C $(DESTDIR) --skip-old-files;; esac


# Golang https://go.dev/dl/
apps += golang
golang_version := 1.23.1
ifeq ($(MSYSTEM),MSYS)
golang_package := go$(golang_version).windows-amd64.zip
else
golang_package := go$(golang_version).linux-amd64.tar.gz
endif
golang: $(golang_package)
$(golang_package):
	wget -c -O $@ https://go.dev/dl/$@

apps += golang-install
golang-install: $(DESTDIR)/go/VERSION pre_install
$(DESTDIR)/go/VERSION: $(golang_package)
	mkdir -p $(DESTDIR)
	case "$<" in *.zip) unzip -DD -d $(DESTDIR) $<;; *.tar.*) tar -xamf $< -C $(DESTDIR);; esac


# Graalvm https://www.oracle.com/java/technologies/downloads/#graalvmjava17-windows
apps += graalvm
graalvm_version := 21
graalvm_package := graalvm-jdk-$(graalvm_version)_$(os)-x64_bin.$(ext)
graalvm: $(graalvm_package)
$(graalvm_package):
	wget -c -O $@ https://download.oracle.com/graalvm/$(graalvm_version)/latest/$@


# Graalvm-package
apps += graalvm-rpm
graalvm_arch := x86_64
graalvm_rpm := apache-graalvm-$(graalvm_version).$(graalvm_arch).rpm
graalvm-rpm: $(graalvm_rpm)
$(graalvm_rpm): $(graalvm_package) $(fpm)
	$(fpm) -s tar -t rpm -n graalvm-jdk -a $(graalvm_arch) --prefix $(DESTDIR) $<


# leininage
apps += leiningen
leiningen: lein.zip
lein.zip:
	wget -c https://raw.githubusercontent.com/technomancy/leiningen/stable/bin/lein
	chmod +x lein
	zip --move --test $@ lein


# TruffleRuby https://github.com/oracle/truffleruby/releases
apps += truffleruby
truffleruby_version := 24.0.2
truffleruby_package := truffleruby-$(truffleruby_version)-$(os)-amd64.$(ext)
truffleruby: $(truffleruby_package)
$(truffleruby_package):
	wget -c -O $@ https://github.com/oracle/truffleruby/releases/download/graal-$(truffleruby_version)/$(truffleruby_package)

apps += truffleruby-install
truffleruby_dir := $(DESTDIR)$(patsubst %.tar.gz,%,$(truffleruby_package))/
truffleruby_bin := $(truffleruby_dir)bin/truffleruby
truffleruby_ref := https://www.graalvm.org/latest/reference-manual/ruby/RubyManagers/#using-truffleruby-without-a-ruby-manager
$(truffleruby_bin): $(truffleruby_package)
	tar -xzmf $(truffleruby_package) -C $(DESTDIR)

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

truffleruby-install: pre_install $(truffleruby_bin) $(truffleruby_deps)

# fpm for unpacking rpm files
apps += fpm-install
fpm := $(truffleruby_dir)/bin/fpm
fpm-install: $(fpm)
$(fpm): $(truffleruby_bin)
	$(truffleruby_bin) -S gem install fpm


# Bitwarden Cli
apps += bitwarden
bitwarden: bw
bw: bw.$(ext)
	if [[ $(ext) = zip ]]; then unzip $<; else tar -xaf $<; fi
bw.$(ext):
	wget -c -O $@ 'https://vault.bitwarden.com/download/?app=cli&platform=$(ow)'


# Babashka https://github.com/babashka/babashka/releases
apps += babashka
babashka_version := 1.3.191
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
babashka_bindir := $(DESTDIR)babashka-$(babashka_version)/bin
else
babashka_bindir := ~/bin
endif
babashka-install: $(babashka_package) pre_install
	mkdir -p $(babashka_bindir)
	[[ "$(babashka_package)" == *.zip ]] && unzip $< -d $(babashka_bindir) || tar -xaf $(babashka_package) -C $(babashka_bindir)


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
jasspa_bindir := $(DESTDIR)jasspa-$(babashka_version)/bin
else
jasspa_bindir := ~/bin
endif
jasspa_2009-install: $(jasspa_bindir)/mec2009 pre_install
$(jasspa_bindir)/mec2009: builddir := $(shell mktemp -d --tmpdir jasspa-XXXXXX)
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
jasspa_bindir := $(DESTDIR)jasspa-$(jasspa_version)/bin
else
jasspa_bindir := ~/bin
endif

ifneq ($(MSYSTEM),)
exe=.exe
endif

jasspa-install: $(jasspa_bindir)/mec$(exe) pre_install
$(jasspa_bindir)/mec$(exe): builddir := $(shell mktemp -d --tmpdir jasspa-XXXXXXX)
$(jasspa_bindir)/mec$(exe): $(jasspa_package)
	tar -xaf $(jasspa_package) -C $(builddir) --strip-components=1
	patch -d $(builddir) -p1 < jasspa.patch
	cd $(builddir) && rm -f bin/me* bin/bfs*
	cd $(builddir)/src && ./build
	cd $(builddir) && make me-bfs-bin
	[ -f $(builddir)/bin/mec-linux.bin ] &&  install -D -m 755 $(builddir)/bin/mec-linux.bin $@ ||:
	[ -f $(builddir)/bin/mec-windows.exe ] && install -D $(builddir)/bin/mec-windows.exe $@ ||:
	test -f $@
	-cp -f $(builddir)/bin/bfs* $(@D)
	rm -rf $(builddir)

apps += phcl-microemacs
phcl-microemacs_pkg := $(patsubst %,phcl-microemacs/%, MicroEmacs-4.21-0.0.src.rpm MicroEmacs-4.21-0.0.x86_64.rpm)
phcl-microemacs: $(phcl-microemacs_pkg)
$(phcl-microemacs_pkg):
	mkdir -p $(@D)
	rsync -Pt rsync://www.phcomp.co.uk/downloads/centos9-x86_64/phcl/$(@F) $(@D)/


## Raku, Perl 6.
apps += rakudo
rakudo_version := 2024.06-01
ifneq ($(MSYSTEM),)
rakudo_package := rakudo-moar-$(rakudo_version)-win-x86_64-msvc.zip
else
rakudo_package := rakudo-moar-$(rakudo_version)-linux-x86_64-gcc.tar.gz
endif

# https://rakudo.org/
rakudo: $(rakudo_package)
$(rakudo_package):
	wget -c -O $@.swp https://rakudo.org/dl/rakudo/$(rakudo_package)
	mv -f $@.swp $@

apps += rakudo-install
rakudo-install: $(rakudo_package) pre_install
	[[ $(rakudo_package) == *.zip ]] && unzip $(rakudo_package) -d $(DESTDIR) || tar xaf $(rakudo_package) -C $(DESTDIR)


# chruby https://github.com/postmodern/chruby/releases
apps += chruby
chruby_version := 0.3.9
chruby_package := chruby-$(chruby_version).tar.gz
chruby: $(chruby_package)
$(chruby_package):
	wget -c -O $@.swp https://github.com/postmodern/chruby/releases/download/v$(chruby_version)/$(chruby_package)
	mv -f $@.swp $@

apps += chruby-install
chruby-install: $(chruby_package) pre_install
	tar -xaf $(chruby_package)
	make -C chruby-$(chruby_version) install PREFIX=$(DESTDIR)/chruby-$(chruby_version)
	-rm -f ~/.bashrc.d/chruby
	echo "# This file is generated automatically, DO NOT EDIT!" > ~/.bashrc.d/chruby
	echo "source $(DESTDIR)/chruby-$(chruby_version)/share/chruby/chruby.sh" >> ~/.bashrc.d/chruby
	echo "source $(DESTDIR)/chruby-$(chruby_version)/share/chruby/auto.sh" >> ~/.bashrc.d/chruby


# ruby-install, ruby installer https://github.com/postmodern/ruby-install/releases
apps += ruby-installer
ruby-installer_version := 0.9.3
ruby-installer_package := ruby-install-$(ruby-installer_version).tar.gz
ruby-installer: $(ruby-installer_package)
$(ruby-installer_package):
	wget -c -O $@.swp https://github.com/postmodern/ruby-install/releases/download/v$(ruby-installer_version)/$(ruby-installer_package)
	mv -f $@.swp $@

ruby-installer-install: $(ruby-installer_package) pre_install
	tar -xaf $(ruby-installer_package)
	make -C ruby-install-$(ruby-installer_version) install PREFIX=$(DESTDIR)/ruby-install-$(ruby-installer_version)


ifeq ($(uname_os), Msys)
# The source file create-short.c is from git-sdk library
# https://github.com/git-for-windows/build-extra
apps += create-shortcut
create-shortcut: create-shortcut.exe
create-shortcut.exe: create-shortcut.c
	/ucrt64/bin/gcc -o $@ $^ -luuid -lole32

create-shortcut.c:
	wget https://raw.githubusercontent.com/git-for-windows/build-extra/main/git-extra/$@
endif

## Add more here.

# All
all: $(apps)

clean:
	-rm -f .*.done

distclean: clean
	-git clean -Xf

.PHONY: all clean distclean pre_install $(apps)
