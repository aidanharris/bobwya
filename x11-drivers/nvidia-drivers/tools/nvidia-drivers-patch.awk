# !/bin/awk

function print_nvidia_kernel_warning_message(indent)
{
	printf("%s%s%s\n",		indent,	indent,	"elif use kms && kernel_is le 4 1; then")
	printf("%s%s%s%s\n",	indent,	indent,	indent, "ewarn \"NVIDIA does not fully support kernel modesetting on\"")
	printf("%s%s%s%s\n",	indent,	indent,	indent, "ewarn \"on the following kernels:\"")
	printf("%s%s%s%s\n",	indent,	indent,	indent, "ewarn \"<sys-kernel/gentoo-sources-4.2\"")
	printf("%s%s%s%s\n",	indent,	indent,	indent, "ewarn \"<sys-kernel/vanilla-sources-4.2\"")
	printf("%s%s%s%s\n",	indent,	indent,	indent, "ewarn")
	if (nvidia_version ~ nvidia_supported_kms_version_regexp) {
		printf("%s%s%s\n",		indent,	indent,	"elif use kms; then")
		printf("%s%s%s%s\n",	indent,	indent,	indent, "einfo \"USE +kms: checking kernel for KMS CONFIG recommended by NVIDIA.\"")
		printf("%s%s%s%s\n",	indent,	indent,	indent, "einfo")
		printf("%s%s%s%s\n",	indent,	indent,	indent, "CONFIG_CHECK+=\" ~DRM_KMS_HELPER ~DRM_KMS_FB_HELPER\"")
	}
	printf("%s%s%s\n",		indent,	indent,	"fi")
}

function print_unofficial_linux_patch_warning_message(indent, array_supported_kernels,
		i_kernel)
{
	if (! (0 in array_supported_kernels))
		return 0
	printf("%s%s%s%s\n",	indent,	indent,	indent, "ewarn \"This version of ${CATEGORY}/${PN} has an unofficial patch\"")
	printf("%s%s%s%s\n",	indent,	indent,	indent, "ewarn \"applied to enable support for the following kernels:\"")
	for (i_kernel=1; i_kernel<=array_supported_kernels[0]; ++i_kernel) {
		sub("^[<>=]+", "=", array_supported_kernels[i_kernel])
		printf("%s%s%s%s\n",	indent,	indent,	indent, ("ewarn \"" array_supported_kernels[i_kernel] "\""))
	}
	return 1
}

function print_nvidia_kms_kernel_modules(indent)
{
	printf("%s%s%s\n",		indent,	indent,	"if use kms; then")
	printf("%s%s%s%s\n",	indent,	indent,	indent, "MODULE_NAMES+=\" nvidia-modeset(video:${S}/kernel)\"")
	printf("%s%s%s%s\n",	indent,	indent,	indent, "MODULE_NAMES+=\" nvidia-drm(video:${S}/kernel)\"")
	printf("%s%s%s\n",		indent,	indent,	"fi")
}

function print_experimental_warning_message(indent)
{
	printf("%s%s\n", indent, "ewarn \"This is an experimental version of ${CATEGORY}/${PN} designed to fix\"")
	printf("%s%s\n", indent, "ewarn \"issues when switching GL providers.\"")
	printf("%s%s\n", indent, "ewarn \"This package should only be used in conjuction with patched versions of:\"")
	printf("%s%s\n", indent, "ewarn \" * app-select/eselect-opengl\"")
	printf("%s%s\n", indent, "ewarn \" * media-libs/mesa\"")
	printf("%s%s\n", indent, "ewarn \" * x11-base/xorg-server\"")
	printf("%s%s\n", indent, "ewarn \"from the bobwya overlay.\"")
	printf("%s%s\n", indent, "ewarn")
}

BEGIN{
	setup_ebuild_phases("pkg_pretend pkg_setup src_prepare src_compile src_install src_install-libs pkg_preinst pkg_postinst pkg_prerm pkg_postrm",
						array_ebuild_phases, array_phase_open, array_ebuild_phases_regexp)

	# Setup some regular expression constants - to hopefully make the script more readable!
	variables="CONFIG_CHECK QA_TEXTRELS_x86 QA_TEXTRELS_x86_fbsd QA_TEXTRELS_amd64 QA_EXECSTACK_x86 QA_EXECSTACK_amd64 QA_WX_LOAD_x86 QA_WX_LOAD_amd64 QA_FLAGS_IGNORED_amd64 QA_FLAGS_IGNORED_x86"
	setup_global_regexps(variables)
	nvidia_glx_libraries_variable_regexp=(leading_ws_regexp "NV\\_GLX\\_LIBRARIES[+]{0,1}\\=\\(")
	eselect_opengl_check_regexp="app\\-eselect\\\/eselect\\-opengl"
	x11_base_xorg_server_regexp="x11\\-base\\\/xorg\\-server"
	X_use_test_regexp="use[[:blank:]]+X"
	use_kernel_linux_regexp="use[[:blank:]]+kernel\\_linux"
	use_kms_regexp="use[[:blank:]]+kms"
	has_version_test_regexp="has\\_version"
	gl_root_regexp="[[:blank:]]+\\$\\{GL\\_ROOT\\}"
	nvidia_xorg_lib_extension_dir_regexp="\\\/opengl\\\/nvidia\\\/extensions"
	nvidia_opengl_lib_dir_regexp="\\\/opengl\\\/nvidia\\\/lib"
	nvidia_xorg_lib_extension_dir="\/xorg\/nvidia\/extensions"
	nvidia_specific_lib_regexp="lib[\\-\\_[:alnum:]]*nvidia[\\-\\_[:alpha:]]*\\.so"
	nvidia_supported_kms_version_regexp=convert_version_list_to_regexp(nvidia_supported_kms_versions)
}
{
	suppress_current_line=0
	if_stack+=($0 ~ if_open_regexp) ? 1 : 0
	if_stack+=($0 ~ if_close_regexp) ? -1 : 0

	if (!preamble_over) {
		if ($0 ~ gentoo_copyright_header_regexp)
			sub("[[:digit:]]{4}\\-[[:digit:]]{4}", "1999-2016")
		if ($0 ~ array_variables_regexp["EAPI"])
			sub("[\"]{0,1}5[\"]{0,1}", 6)

		for (i_variable_regexp in array_variables_regexp) {
			if ($0 ~ array_variables_regexp[i_variable_regexp]) {
				variable_declaration_open=1
				break
			}
		}
		if (variable_declaration_open == 1) {
			gsub(nvidia_xorg_lib_extension_dir_regexp, nvidia_xorg_lib_extension_dir)
		}
		if ($0 ~ end_quote_regexp)
			variable_declaration_open=0

		# Change dependency on app-eselect/eselect_opengl to an out-of-tree, patched version
		if ($0 ~ (leading_ws_regexp ebuild_version_comparision_regexp eselect_opengl_check_regexp)) {
			sub(package_version_regexp, ("-" eselect_opengl_supported_version))
			sub(/>=/, "=")
		}
		if ($0 ~ (leading_ws_regexp ebuild_version_comparision_regexp x11_base_xorg_server_regexp)) {
			printf("%s%s>=x11-base/xorg-server-%s\n", indent, indent, xorg_server_supported_version)
			suppress_current_line=1
		}

		# Mark all converted ebuilds as unstable
		if ($0 ~ keywords_regexp)
			$0=gensub(keyword_regexp, "~\\1", "g")
	}

	# Ebuild phase process opening stanzas for functions
	if (process_ebuild_phase_open($0, array_ebuild_phases, array_phase_open, array_ebuild_phases_regexp)) {
		preamble_over=1
		target_block_open=0
	}

	# Ebuild phase based pre-checks
	if (array_phase_open["pkg_pretend"]) {
		sub(text2regexp("[ \"${DEFAULT_ABI}\" != \"amd64\" ]"), "[&]")
		if (!kernel_linux_block_open && ($0 ~ if_open_regexp) && ($0 ~ text2regexp("use kernel_linux")) && (if_stack == 1)) {
			kernel_linux_block_open=1
			if (nvidia_version ~ nvidia_supported_kms_version_regexp)
				printf("%s%s\n", indent, "CONFIG_CHECK=\"\"")
			printf("%s%s\n", indent, "if use kernel_linux; then")
			sub(text2regexp("use kernel_linux && "), "")
			sub(("^" indent), (indent indent))
		}
		else if (kernel_linux_block_open == 1) {
			if ($0 ~ text2regexp("^ ewarn \"\""))
				++kernel_linux_block_open
			else {
				sub(("^" indent), (indent indent))
				match($0, "<sys\\-kernel\\/[\\-[:alpha:]]+[\\.[:digit:]]+(|\\-r[[:digit:]]+)" )
				if (RSTART)
					array_supported_kernels[++array_supported_kernels[0]]=substr($0, RSTART, RLENGTH)
			}
		}
		if (kernel_linux_block_open == 2) {
			if ($0 !~ text2regexp("^ ewarn")) {
				#if (is_unofficial_linux_kernel_patch)
				print_unofficial_linux_patch_warning_message(indent, array_supported_kernels)
				++kernel_linux_block_open
			}
			else
				suppress_current_line=1
		}
		if (kernel_linux_block_open == 3) {
			print_nvidia_kernel_warning_message(indent)
			++kernel_linux_block_open
		}
		if ((nvidia_version ~ nvidia_supported_kms_version_regexp) && (kernel_linux_block_open == 4) && ($0 ~ array_variables_regexp["CONFIG_CHECK"])) {
			sub("=\"", "+=\" ")
			#++kernel_linux_block_open
		}
	}
	else if ((array_phase_open["pkg_setup"] == 1) && (nvidia_version ~ nvidia_supported_kms_version_regexp) && ($0 ~ (leading_ws_regexp use_kms_regexp))) {
		# keep repoman happy!
		print_nvidia_kms_kernel_modules(indent)
		suppress_current_line=1
		++array_phase_open["pkg_setup"]
	}
	else if (array_phase_open["src_prepare"]) {
		if (local_patches_declared) {
			if ($0 ~ text2regexp("^ (epatch|eapply) *.patch",1))
				$0=gensub(text2regexp("(epatch|eapply) (*.patch)",2), "PATCHES+=( \\2 )", 1)
		}
		else if ($0 ~ if_open_regexp) {
			printf("%s%s\n", indent,	"local PATCHES")
			local_patches_declared=1
		}
		else if ($0 ~ text2regexp("^ (epatch|eapply) *.patch",1)) {
			$0=gensub(text2regexp("(epatch|eapply) (*.patch)",2), "local PATCHES=( \\2 )", 1)
			local_patches_declared=1
		}
		sub(text2regexp("(eapply_user|epatch_user)",1), "default")
	}
	else if (array_phase_open["src_install"]) {

		gsub(nvidia_xorg_lib_extension_dir_regexp, nvidia_xorg_lib_extension_dir)
		if (($0 ~ if_open_regexp) && ($0 ~ text2regexp("has_version *x11-base/xorg-server")) && (if_stack == 2)) {
			has_version_xorg_server_open=1
			suppress_current_line=1
		}
		if (has_version_xorg_server_open) {
			sub("\\t", "")
			if ($0 ~ if_close_regexp) {
				suppress_current_line=1
				has_version_xorg_server_open=0
			}
		}
	}
	else if (array_phase_open["src_install-libs"]) {
		if (($0 ~ (if_open_regexp X_use_test_regexp)) && (if_stack == 1))
			if_use_X_open=1
		if (if_use_X_open) {
			if ($0 ~ nvidia_glx_libraries_variable_regexp)
				nvidia_glx_libraries_variable_open=1
			donvidia_call_open=donvidia_call_open || ($0 ~ text2regexp("^ donvidia"))
		}
		if (($0 ~ nvidia_specific_lib_regexp) && (nvidia_glx_libraries_variable_open || donvidia_call_open)) {
			sub(gl_root_regexp, "")
		}
		if ($0 ~ end_quote_regexp)
			donvidia_call_open=0
		if ($0 ~ closing_bracket_regexp)
			nvidia_glx_libraries_variable_open=0
		if (($0 ~ if_close_regexp) && (if_stack == 1))
			if_use_X_open=0
	}
	else if (array_phase_open["pkg_postinst"] &&  ($0 ~ end_curly_bracket_regexp)) {
		print_experimental_warning_message(indent)
	}
	if (array_phase_open["pkg_prerm"] || array_phase_open["pkg_postrm"]) {
		if ($0 ~ text2regexp("eselect opengl"))
			sub(text2regexp("xorg-x11"), "mesa")
	}

	# Print current line in ebuild
	if (!suppress_current_line)
		print $0

	# Extract whitespace type and indent level for current line in the ebuild - so we step lightly!
	if (match($0, leading_ws_regexp))
		indent=(indent == 0) ? substr($0, RSTART, RLENGTH) : indent


	# Ebuild phase based post-checks
	if (array_phase_open["src_prepare"]) {
		if (!nvidia_kernel_patch && (nvidia_version ~ text2regexp("^367.35"))) {
			printf("%s%s\n", indent,	"local PATCHES=( \"${FILESDIR}/${PN}-367.35-kernel-4.7.0.patch\" )")
			nvidia_kernel_patch=1
			local_patches_declared=1
		}
	}

	# Ebuild phase process closing stanzas for functions
	process_ebuild_phase_close($0, array_ebuild_phases, array_phase_open)
}
