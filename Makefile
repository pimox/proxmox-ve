RELEASE=5.1
PACKAGE=proxmox-ve
PKGREL=42

GITVERSION:=$(shell git rev-parse HEAD)

PVE_DEB=${PACKAGE}_${RELEASE}-${PKGREL}_all.deb
PVE_HEADERS_DEB=pve-headers_${RELEASE}-${PKGREL}_all.deb

BUILD_DIR=build

DEBS=${PVE_DEB} ${PVE_HEADERS_DEB}

all: deb
deb: ${DEBS}

${PVE_HEADERS_DEB}: ${PVE_DEB}
${PVE_DEB}: debian
	rm -rf ${BUILD_DIR}
	mkdir -p ${BUILD_DIR}/debian
	cp -ar debian/* ${BUILD_DIR}/debian/
	echo "git clone git://git.proxmox.com/git/proxmox-ve.git\\ngit checkout ${GITVERSION}" > ${BUILD_DIR}/debian/SOURCE
	cd ${BUILD_DIR}; dpkg-buildpackage -b -uc -us
	lintian ${PVE_DEB}

.PHONY: upload
upload: ${DEBS}
	tar cf - ${DEBS}|ssh repoman@repo.proxmox.com -- upload --product pve --dist stretch --arch ${ARCH}

.PHONY: distclean
distclean: clean

.PHONY: clean
clean:
	rm -rf *~ ${BUILD_DIR} *.deb *.dsc *.changes *.buildinfo
