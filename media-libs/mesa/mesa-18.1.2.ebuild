# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

# shellcheck disable=SC2034
EAPI=6

PYTHON_COMPAT=( python2_7 )

inherit autotools llvm multilib-minimal python-any-r1 pax-utils
OPENGL_DIR="${PN}"

MY_P="${P/_/-}"

DESCRIPTION="OpenGL-like graphic library for Linux"
HOMEPAGE="https://www.mesa3d.org/ https://mesa.freedesktop.org/
		https://mesa.freedesktop.org/"
if [[ "${PV}" == "9999" ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://anongit.freedesktop.org/git/mesa/mesa.git"
	EGIT_CHECKOUT_DIR="${WORKDIR}/${MY_P}"
	SRC_URI=""
else
	SRC_URI="https://mesa.freedesktop.org/archive/${MY_P}.tar.xz"
	KEYWORDS="~alpha ~amd64 ~arm ~arm64 ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~amd64-fbsd ~x86-fbsd ~amd64-linux ~arm-linux ~x86-linux ~sparc-solaris ~x64-solaris ~x86-solaris"
fi

LICENSE="MIT"
SLOT="0"
RESTRICT="!bindist? ( bindist )"

AMD_CARDS=( "r100" "r200" "r300" "r600" "radeon" "radeonsi" )
INTEL_CARDS=( "i915" "i965" "intel" )
VIDEO_CARDS=( "freedreno" "imx" "nouveau" "vc4" "virgl" "vivante" "vmware" )
VIDEO_CARDS+=( "${AMD_CARDS[@]}" )
VIDEO_CARDS+=( "${INTEL_CARDS[@]}" )
for card in "${VIDEO_CARDS[@]}"; do
	IUSE_VIDEO_CARDS+=" video_cards_${card}"
done

IUSE="${IUSE_VIDEO_CARDS}
	bindist +classic d3d9 debug +dri3 +egl +gallium +gbm gles1 gles2 unwind
	+llvm +nptl opencl osmesa pax_kernel openmax pic selinux vaapi valgrind
	vdpau vulkan wayland xvmc xa"

REQUIRED_USE="
	d3d9?   ( dri3 gallium )
	llvm?   ( gallium )
	opencl? ( gallium llvm )
	openmax? ( gallium )
	gles1?  ( egl )
	gles2?  ( egl )
	vaapi? ( gallium )
	vdpau? ( gallium )
	vulkan? ( || ( video_cards_i965 video_cards_radeonsi )
			  video_cards_radeonsi? ( llvm ) )
	wayland? ( egl gbm )
	xa?  ( gallium )
	video_cards_freedreno?  ( gallium )
	video_cards_intel?  ( classic )
	video_cards_i915?   ( || ( classic gallium ) )
	video_cards_i965?   ( classic )
	video_cards_imx?	( gallium video_cards_vivante )
	video_cards_nouveau? ( || ( classic gallium ) )
	video_cards_radeon? ( || ( classic gallium )
						  gallium? ( x86? ( llvm ) amd64? ( llvm ) ) )
	video_cards_r100?   ( classic )
	video_cards_r200?   ( classic )
	video_cards_r300?   ( gallium x86? ( llvm ) amd64? ( llvm ) )
	video_cards_r600?   ( gallium )
	video_cards_radeonsi?   ( gallium llvm )
	video_cards_vc4? ( gallium )
	video_cards_virgl? ( gallium )
	video_cards_vivante? ( gallium gbm )
	video_cards_vmware? ( gallium )
"

LIBDRM_DEPSTRING=">=x11-libs/libdrm-2.4.91"
# shellcheck disable=SC2124
RDEPEND="
	!app-eselect/eselect-mesa
	=app-eselect/eselect-opengl-1.3.3-r1
	>=dev-libs/expat-2.1.0-r3:=[${MULTILIB_USEDEP}]
	>=sys-libs/zlib-1.2.8[${MULTILIB_USEDEP}]
	>=x11-libs/libX11-1.6.2:=[${MULTILIB_USEDEP}]
	>=x11-libs/libxshmfence-1.1:=[${MULTILIB_USEDEP}]
	>=x11-libs/libXdamage-1.1.4-r1:=[${MULTILIB_USEDEP}]
	>=x11-libs/libXext-1.3.2:=[${MULTILIB_USEDEP}]
	>=x11-libs/libXxf86vm-1.1.3:=[${MULTILIB_USEDEP}]
	>=x11-libs/libxcb-1.13:=[${MULTILIB_USEDEP}]
	x11-libs/libXfixes:=[${MULTILIB_USEDEP}]
	unwind? ( sys-libs/libunwind[${MULTILIB_USEDEP}] )
	llvm? (
		video_cards_radeonsi? (
			virtual/libelf:0=[${MULTILIB_USEDEP}]
		)
		video_cards_r600? (
			virtual/libelf:0=[${MULTILIB_USEDEP}]
		)
		video_cards_radeon? (
			virtual/libelf:0=[${MULTILIB_USEDEP}]
		)
	)
	opencl? (
		app-eselect/eselect-opencl
		dev-libs/libclc
		virtual/libelf:0=[${MULTILIB_USEDEP}]
	)
	openmax? (
		>=media-libs/libomxil-bellagio-0.9.3:=[${MULTILIB_USEDEP}]
		x11-misc/xdg-utils
	)
	vaapi? (
		>=x11-libs/libva-1.7.3:=[${MULTILIB_USEDEP}]
		video_cards_nouveau? ( !<=x11-libs/libva-vdpau-driver-0.7.4-r3 )
	)
	vdpau? ( >=x11-libs/libvdpau-1.1:=[${MULTILIB_USEDEP}] )
	wayland? (
		>=dev-libs/wayland-1.11.0:=[${MULTILIB_USEDEP}]
		>=dev-libs/wayland-protocols-1.8
	)
	xvmc? ( >=x11-libs/libXvMC-1.0.8:=[${MULTILIB_USEDEP}] )
	${LIBDRM_DEPSTRING}[video_cards_freedreno?,video_cards_nouveau?,video_cards_vc4?,video_cards_vivante?,video_cards_vmware?,${MULTILIB_USEDEP}]
"

# shellcheck disable=SC2068
for card in ${INTEL_CARDS[@]}; do
	RDEPEND="${RDEPEND}
		video_cards_${card}? ( ${LIBDRM_DEPSTRING}[video_cards_intel] )
	"
done
# shellcheck disable=SC2068
for card in ${AMD_CARDS[@]}; do
	RDEPEND="${RDEPEND}
		video_cards_${card}? ( ${LIBDRM_DEPSTRING}[video_cards_radeon] )
	"
done
RDEPEND="${RDEPEND}
	video_cards_radeonsi? ( ${LIBDRM_DEPSTRING}[video_cards_amdgpu] )
"

# Please keep the LLVM dependency block separate. Since LLVM is slotted,
# we need to *really* make sure we're only using one slot.
LLVM_DEPSTR="
	|| (
		sys-devel/llvm:7[${MULTILIB_USEDEP}]
		sys-devel/llvm:6[${MULTILIB_USEDEP}]
		sys-devel/llvm:5[${MULTILIB_USEDEP}]
		sys-devel/llvm:4[${MULTILIB_USEDEP}]
		>=sys-devel/llvm-3.9.0:0[${MULTILIB_USEDEP}]
	)
	sys-devel/llvm:=[${MULTILIB_USEDEP}]
"
LLVM_DEPSTR_AMDGPU="${LLVM_DEPSTR//]/,llvm_targets_AMDGPU(-)]}"
CLANG_DEPSTR="${LLVM_DEPSTR//llvm/clang}"
CLANG_DEPSTR_AMDGPU="${CLANG_DEPSTR//]/,llvm_targets_AMDGPU(-)]}"
RDEPEND="${RDEPEND}
	llvm? (
		opencl? (
			video_cards_r600? (
				${CLANG_DEPSTR_AMDGPU}
			)
			!video_cards_r600? (
				video_cards_radeonsi? (
					${CLANG_DEPSTR_AMDGPU}
				)
				!video_cards_radeonsi? (
					video_cards_radeon? (
						${CLANG_DEPSTR_AMDGPU}
					)
					!video_cards_radeon? (
						${CLANG_DEPSTR}
					)
				)
			)
		)
		!opencl? (
			video_cards_r600? (
				${LLVM_DEPSTR_AMDGPU}
			)
			!video_cards_r600? (
				video_cards_radeonsi? (
					${LLVM_DEPSTR_AMDGPU}
				)
				!video_cards_radeonsi? (
					video_cards_radeon? (
						${LLVM_DEPSTR_AMDGPU}
					)
					!video_cards_radeon? (
						${LLVM_DEPSTR}
					)
				)
			)
		)
	)
"
unset {LLVM,CLANG}_DEPSTR{,_AMDGPU}

DEPEND="${RDEPEND}
	${PYTHON_DEPS}
	opencl? (
		>=sys-devel/gcc-4.6
	)
	sys-devel/gettext
	virtual/pkgconfig
	valgrind? ( dev-util/valgrind )
	x11-base/xorg-proto
	vulkan? (
		$(python_gen_any_dep ">=dev-python/mako-0.7.3[\${PYTHON_USEDEP}]")
	)
"

[[ "${PV}" == "9999" ]] && DEPEND+="
	sys-devel/bison
	sys-devel/flex
	$(python_gen_any_dep ">=dev-python/mako-0.7.3[\${PYTHON_USEDEP}]")
"

S="${WORKDIR}/${MY_P}"
EGIT_CHECKOUT_DIR="${S}"

QA_WX_LOAD="
x86? (
	!pic? (
		usr/lib*/libglapi.so.0.0.0
		usr/lib*/libGLESv1_CM.so.1.1.0
		usr/lib*/libGLESv2.so.2.0.0
		usr/lib*/libGL.so.1.2.0
		usr/lib*/libOSMesa.so.8.0.0
	)
"

# driver_enable DRI_DRIVERS()
#	1>	 driver array (reference)
#	2>	 driver USE flag (main category)
#	[3-N]> driver USE flags (subcategory)
driver_enable() {
	(($# < 2)) && die "Invalid parameter count: ${#} (2)"
	local __driver_array_reference="${1}" __driver_use_flag="${2}" driver
	declare -n driver_array=${__driver_array_reference}

	if (($# == 2)); then
		driver_array+=",${__driver_use_flag}"
	elif use "${__driver_use_flag}"; then
		# shellcheck disable=SC2068
		for driver in ${@:3}; do
			driver_array+=",${driver}"
		done
	fi
}

llvm_check_depends() {
	local flags="${MULTILIB_USEDEP}"
	if use video_cards_r600 || use video_cards_radeon || use video_cards_radeonsi; then
		flags+=",llvm_targets_AMDGPU(-)"
	fi
	if use opencl; then
		has_version "sys-devel/clang[${flags}]" || return 1
	fi
	has_version "sys-devel/llvm[${flags}]"
}

pkg_setup() {
	# warning message for bug 459306
	if use llvm && has_version sys-devel/llvm[!debug=]; then
		ewarn "Mismatch between debug USE flags in media-libs/mesa and sys-devel/llvm"
		ewarn "detected! This can cause problems. For details, see bug 459306."
	fi

	if use llvm; then
		llvm_pkg_setup
	fi
	python-any-r1_pkg_setup
}

src_prepare() {
	default
	[[ "${PV}" == "9999" ]] && eautoreconf
}

multilib_src_configure() {
	local myeconfargs

	if use classic; then
		# Configurable DRI drivers
		driver_enable DRI_DRIVERS swrast

		# Intel code
		driver_enable DRI_DRIVERS video_cards_i915 i915
		driver_enable DRI_DRIVERS video_cards_i965 i965
		if ! use video_cards_i915 && ! use video_cards_i965; then
			driver_enable DRI_DRIVERS video_cards_intel i915 i965
		fi

		# Nouveau code
		driver_enable DRI_DRIVERS video_cards_nouveau nouveau

		# ATI code
		driver_enable DRI_DRIVERS video_cards_r100 radeon
		driver_enable DRI_DRIVERS video_cards_r200 r200
		if ! use video_cards_r100 && ! use video_cards_r200; then
			driver_enable DRI_DRIVERS video_cards_radeon radeon r200
		fi
	fi

	if use egl; then
		myeconfargs+=( "--with-egl-platforms=x11,surfaceless$(use wayland && echo ",wayland")$(use gbm && echo ",drm")" )
	fi

	if use gallium; then
		myeconfargs+=(
			"$(use_enable d3d9 nine)"
			"$(use_enable llvm)"
			"$(use_enable openmax omx-bellagio)"
			"$(use_enable vaapi va)"
			"$(use_enable vdpau)"
			"$(use_enable xa)"
			"$(use_enable xvmc)"
		)
		use vaapi && myeconfargs+=( "--with-va-libdir=/usr/$(get_libdir)/va/drivers" )

		driver_enable GALLIUM_DRIVERS swrast
		driver_enable GALLIUM_DRIVERS video_cards_vc4 vc4
		driver_enable GALLIUM_DRIVERS video_cards_virgl virgl
		driver_enable GALLIUM_DRIVERS video_cards_vivante etnaviv
		driver_enable GALLIUM_DRIVERS video_cards_vmware svga
		driver_enable GALLIUM_DRIVERS video_cards_nouveau nouveau
		driver_enable GALLIUM_DRIVERS video_cards_i915 i915
		driver_enable GALLIUM_DRIVERS video_cards_imx imx
		if ! use video_cards_i915 && ! use video_cards_i965; then
			driver_enable GALLIUM_DRIVERS video_cards_intel i915
		fi

		driver_enable GALLIUM_DRIVERS video_cards_r300 r300
		driver_enable GALLIUM_DRIVERS video_cards_r600 r600
		driver_enable GALLIUM_DRIVERS video_cards_radeonsi radeonsi
		if ! use video_cards_r300 && ! use video_cards_r600; then
			driver_enable GALLIUM_DRIVERS video_cards_radeon r300 r600
		fi

		driver_enable GALLIUM_DRIVERS video_cards_freedreno freedreno
		# opencl stuff
		if use opencl; then
			myeconfargs+=(
				"$(use_enable opencl)"
				"--with-clang-libdir=${EPREFIX}/usr/lib"
				)
		fi
	fi

	if use vulkan; then
		driver_enable VULKAN_DRIVERS video_cards_i965 intel
		driver_enable VULKAN_DRIVERS video_cards_radeonsi radeon
	fi
	# x86 hardened pax_kernel needs glx-rts, bug 240956
	if [[ "${ABI}" == "x86" ]]; then
		myeconfargs+=( "$(use_enable pax_kernel glx-read-only-text)" )
	fi

	# on abi_x86_32 hardened we need to have asm disable
	if [[ ${ABI} == x86* ]] && use pic; then
		myeconfargs+=( "--disable-asm" )
	fi

	if use gallium; then
		myeconfargs+=( "$(use_enable osmesa gallium-osmesa)" )
	else
		myeconfargs+=( "$(use_enable osmesa)" )
	fi

	# build fails with BSD indent, bug #428112
	use userland_GNU || export INDENT=cat

	myeconfargs+=(
		"--enable-dri"
		"--enable-glx"
		"--enable-shared-glapi"
		"$(use_enable !bindist texture-float)"
		"$(use_enable d3d9 nine)"
		"$(use_enable debug)"
		"$(use_enable dri3)"
		"$(use_enable egl)"
		"$(use_enable gbm)"
		"$(use_enable gles1)"
		"$(use_enable gles2)"
		"$(use_enable nptl glx-tls)"
		"$(use_enable unwind libunwind)"
		"--enable-valgrind=$(usex valgrind auto no)"
		"--enable-llvm-shared-libs"
		"--disable-opencl-icd"
		"--with-dri-drivers=${DRI_DRIVERS}"
		"--with-gallium-drivers=${GALLIUM_DRIVERS}"
		"--with-vulkan-drivers=${VULKAN_DRIVERS}"
		"PYTHON2=${PYTHON}"
	)
	# shellcheck disable=SC2068,SC2128
	ECONF_SOURCE="${S}" econf ${myeconfargs[@]}
}

multilib_src_install() {
	emake install DESTDIR="${D}"

	if use wayland; then

		# These files are now provided by >=dev-libs/wayland-1.15.0
		rm "${ED}/usr/$(get_libdir)/libwayland-egl.so" || die "rm failed"
		rm "${ED}/usr/$(get_libdir)/libwayland-egl.so.1" || die "rm failed"
		rm "${ED}/usr/$(get_libdir)/libwayland-egl.so.1.0.0" || die "rm failed"
		rm "${ED}/usr/$(get_libdir)/pkgconfig/wayland-egl.pc" || die "rm failed"
	fi

	# Move lib{EGL*,GL*,OpenVG,OpenGL}.{la,a,so*} files from /usr/lib to /usr/lib/opengl/mesa/lib
	ebegin "(subshell): moving lib{EGL*,GL*,OpenGL}.{la,a,so*} in order to implement dynamic GL switching support"
	(
		local gl_dir
		gl_dir="/usr/$(get_libdir)/opengl/${OPENGL_DIR}"
		dodir "${gl_dir}/lib"
		for library in "${ED%/}/usr/$(get_libdir)"/lib{EGL*,GL*,OpenGL}.{la,a,so*} ; do
			if [[ -f ${library} || -L ${library} ]]; then
				mv -f "${library}" "${ED%/}${gl_dir}"/lib \
					|| die "Failed to move ${library}"
			fi
		done
	)
	eend $? || die "(subshell): failed to move lib{EGL*,GL*,OpenGL}.{la,a,so*}"

	if use openmax; then
		echo "XDG_DATA_DIRS=\"${EPREFIX}/usr/share/mesa/xdg\"" > "${T}/99mesaxdgomx"
		doenvd "${T}"/99mesaxdgomx
		keepdir /usr/share/mesa/xdg
	fi
}

multilib_src_install_all() {
	find "${ED%/}" -name '*.la' -delete
	einstalldocs

	if use !bindist; then
		dodoc "docs/patents.txt"
	fi

}

multilib_src_test() {
	if use llvm; then
		local llvm_tests='lp_test_arit lp_test_arit lp_test_blend lp_test_blend lp_test_conv lp_test_conv lp_test_format lp_test_format lp_test_printf lp_test_printf'
		pushd "src/gallium/drivers/llvmpipe" >/dev/null || die "pushd failed"
		# shellcheck disable=SC2086
		emake ${llvm_tests}
		# shellcheck disable=SC2086
		pax-mark m ${llvm_tests}
		popd >/dev/null || die "popd failed"
	fi
	emake check
}

pkg_postinst() {
	# Switch to the xorg implementation.
	echo
	eselect opengl set --use-old "${OPENGL_DIR}"

	# Switch to mesa opencl
	if use opencl; then
		eselect opencl set --use-old "${PN}"
	fi

	# run omxregister-bellagio to make the OpenMAX drivers known system-wide
	if use openmax; then
		ebegin "(subshell): registering OpenMAX drivers"
		BELLAGIO_SEARCH_PATH="${EPREFIX}/usr/$(get_libdir)/libomxil-bellagio0" \
			OMX_BELLAGIO_REGISTRY="${EPREFIX}/usr/share/mesa/xdg/.omxregister" \
			omxregister-bellagio
		eend $? || die "(subshell): registering OpenMAX drivers failed"
	fi

	# warn about patent encumbered texture-float
	if use !bindist; then
		elog "USE=\"bindist\" was not set. Potentially patent encumbered code was"
		elog "enabled. Please see /usr/share/doc/${P}/patents.txt.bz2 for an"
		elog "explanation."
	fi

	ewarn "This is an experimental version of ${CATEGORY}/${PN} designed to fix various issues"
	ewarn "when switching GL providers."
	ewarn "This package can only be used in conjuction with patched versions of:"
	ewarn " * app-select/eselect-opengl"
	ewarn " * x11-base/xorg-server"
	ewarn " * x11-drivers/nvidia-drivers"
	ewarn "from the bobwya overlay."
}

pkg_prerm() {
	if use openmax; then
		rm "${EPREFIX}/usr/share/mesa/xdg/.omxregister"
	fi
}
