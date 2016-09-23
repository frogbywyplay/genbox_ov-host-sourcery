# Copyright 2015 Wyplay/ST

EAPI=1

inherit eutils 

DESCRIPTION="Code Sourcery Generic Toolchain"
HOMEPAGE="https://www.mentor.com/embedded-software/sourcery-tools/sourcery-codebench/overview"
SRC_URI="mirror://sourcery/arm-2012.09.tar.bz2"

LICENSE="GPL"
SLOT="0"
KEYWORDS="x86-host"
IUSE=""
RESTRICT="strip nomirror"

DEPEND="sys-apps/dtc"
RDEPEND="dev-util/ccache"
PROVIDE="virtual/${CATEGORY}-gcc
virtual/${CATEGORY}-glibc"

COMPILER_DIR="/opt/toolchains/arm-2012.09"
COMPILER_TOPDIR="${COMPILER_DIR}/bin"

CTNG_PREFIX="arm-2012.09"
S="${WORKDIR}/${CTNG_PREFIX}"



SYSTEM_TUPLES="arm-sourcery-linux-gnu"
CT_PREFIX="arm-none-linux-gnueabi"
ORIG_SYSTEM_TUPLES="arm-none-linux-gnueabi"

XGCC_VERSION="4.7.2"
XBINUTILS_VERSION="2.23"
BINUTILS_BIN_PATH="/usr/${CHOST}/${SYSTEM_TUPLES}/binutils-bin/${XBINUTILS_VERSION}"
BINUTILS_LIB_PATH="/usr/lib/binutils/${SYSTEM_TUPLES}/${XBINUTILS_VERSION}"
GCC_BIN_PATH="/usr/${CHOST}/${SYSTEM_TUPLES}/gcc-bin/${XGCC_VERSION}"
GCC_LIB_PATH="/usr/lib/gcc/${SYSTEM_TUPLES}/${XGCC_VERSION}"

src_install() {
	dodir ${COMPILER_DIR}
	cp -a ${S}/* ${D}/${COMPILER_DIR}

	# another setup
	dosym "${COMPILER_DIR}/lib/gcc/${CT_PREFIX}/${XGCC_VERSION}" "${GCC_LIB_PATH}"

	# install binutils ldscripts
	dosym "${COMPILER_DIR}/${CT_PREFIX}/lib/ldscripts" "${BINUTILS_LIB_PATH}"


	sed -e "s|@COMPILER_DIR@|${COMPILER_DIR}|g" \
		-e "s|@TUPLES@|${SYSTEM_TUPLES}|g" \
		-e "s|@CT_PREFIX@|${ORIG_SYSTEM_TUPLES}|g" "${FILESDIR}"/"${SYSTEM_TUPLES}"-GCC-BIN > "${T}"/"${SYSTEM_TUPLES}"-GCC-BIN

	# install a directory used by gcc/binutils-config
	dodir "${GCC_BIN_PATH}"
	exeinto "${GCC_BIN_PATH}"
	for ii in c++ cpp g++ gcc gcc-${XGCC_VERSION} gcov; do
		newexe "${T}"/"${SYSTEM_TUPLES}"-GCC-BIN "${SYSTEM_TUPLES}"-$ii
	done

	sed -e "s|@COMPILER_DIR@|${COMPILER_DIR}|g" -e "s|@TUPLES@|${SYSTEM_TUPLES}|g" -e "s|@CT_PREFIX@|${CT_PREFIX}|g" "${FILESDIR}"/"${SYSTEM_TUPLES}"-BINUTILS-BIN > "${T}"/"${SYSTEM_TUPLES}"-BINUTILS-BIN
	dodir "${BINUTILS_BIN_PATH}"
	exeinto "${BINUTILS_BIN_PATH}"
	for ii in ar as ld nm objcopy objdump ranlib strip; do
		newexe "${T}"/"${SYSTEM_TUPLES}"-BINUTILS-BIN $ii
	done

	sed -e "s|@COMPILER_DIR@|${COMPILER_DIR}|g" \
		-e "s|@TUPLES@|${SYSTEM_TUPLES}|g" \
		-e "s|@CT_PREFIX@|${ORIG_SYSTEM_TUPLES}|g" "${FILESDIR}"/"${SYSTEM_TUPLES}"-BINUTILS-BIN-2 > "${T}"/"${SYSTEM_TUPLES}"-BINUTILS-BIN-2
	for ii in addr2line c++filt gprof readelf size strings; do
		newexe "${T}"/"${SYSTEM_TUPLES}"-BINUTILS-BIN-2 $ii
	done

	# create required file for gcc-config
	cat > ${T}/gcc-config.env.d << EOF
LDPATH="${GCC_LIB_PATH}"
CTARGET=${SYSTEM_TUPLES}
GCC_PATH="${GCC_BIN_PATH}"
EOF
	insinto /etc/env.d/gcc
	newins ${T}/gcc-config.env.d ${SYSTEM_TUPLES}-${XGCC_VERSION}

	cat > ${T}/binutils-config.env.d << EOF
TARGET="${SYSTEM_TUPLES}"
VER="${XBINUTILS_VERSION}"
LIBPATH="${BINUTILS_LIB_PATH}"
FAKE_TARGETS="${SYSTEM_TUPLES}"
EOF
	insinto /etc/env.d/binutils
	newins ${T}/binutils-config.env.d "${SYSTEM_TUPLES}-${XBINUTILS_VERSION}"
}

pkg_postinst() {
	gcc-config "${SYSTEM_TUPLES}-${XGCC_VERSION}"
	binutils-config "${SYSTEM_TUPLES}-${XBINUTILS_VERSION}"
	ccache-config --install-links ${SYSTEM_TUPLES}
}
