RELEASE=5.1

# also update proxmox-ve/changelog if you change KERNEL_VER or KREL
KERNEL_VER=4.13.13
PKGREL=39
KREL=6

EXTRAVERSION=-${KREL}-pve
KVNAME=${KERNEL_VER}${EXTRAVERSION}

GITVERSION:=$(shell git rev-parse HEAD)
CHANGELOG_DATE:=$(shell dpkg-parsechangelog -SDate -lchangelog.Debian)
export SOURCE_DATE_EPOCH ?= $(shell dpkg-parsechangelog -STimestamp -lchangelog.Debian)

PACKAGE=proxmox-ve
PVE_DEB=${PACKAGE}_${RELEASE}-${PKGREL}_all.deb

DEBS=${PVE_DEB}

all: deb
deb: ${DEBS}

${PVE_DEB}: proxmox-ve/control proxmox-ve/postinst ${PVE_RELEASE_KEYS}
	rm -rf proxmox-ve/data
	mkdir -p proxmox-ve/data/DEBIAN
	mkdir -p proxmox-ve/data/usr/share/doc/${PACKAGE}/
	mkdir -p proxmox-ve/data/etc/apt/trusted.gpg.d
	install -m 0644 proxmox-ve/proxmox-release-5.x.pubkey proxmox-ve/data/etc/apt/trusted.gpg.d/proxmox-ve-release-5.x.gpg
	sed -e 's/@KVNAME@/${KVNAME}/' -e 's/@KERNEL_VER@/${KERNEL_VER}/' -e 's/@RELEASE@/${RELEASE}/' -e 's/@PKGREL@/${PKGREL}/' <proxmox-ve/control >proxmox-ve/data/DEBIAN/control
	sed -e 's/@KVNAME@/${KVNAME}/' <proxmox-ve/postinst >proxmox-ve/data/DEBIAN/postinst
	chmod 0755 proxmox-ve/data/DEBIAN/postinst
	install -m 0755 proxmox-ve/postrm proxmox-ve/data/DEBIAN/postrm
	echo "git clone git://git.proxmox.com/git/pve-kernel.git\\ngit checkout ${GITVERSION}" > proxmox-ve/data/usr/share/doc/${PACKAGE}/SOURCE
	install -m 0644 proxmox-ve/copyright proxmox-ve/data/usr/share/doc/${PACKAGE}
	install -m 0644 proxmox-ve/changelog.Debian proxmox-ve/data/usr/share/doc/${PACKAGE}
	gzip -n --best proxmox-ve/data/usr/share/doc/${PACKAGE}/changelog.Debian
	dpkg-deb --build proxmox-ve/data ${PVE_DEB}

.PHONY: upload
upload: ${DEBS}
	tar cf - ${DEBS}|ssh repoman@repo.proxmox.com -- upload --product pve --dist stretch --arch ${ARCH}

.PHONY: distclean
distclean: clean

.PHONY: clean
clean:
	rm -rf *~ ${BUILD_DIR} *.deb *.dsc *.changes *.buildinfo
