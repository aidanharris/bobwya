# !/bin/bash

# Absolute path to this script.
script_path=$(readlink -f $0)
# Absolute path this script is in.
script_folder=$( dirname "${script_path}" )
script_name=$( basename "${script_path}" )

# Global version constants
eselect_opengl_supported_version="1.3.2"
mesa_supported_version="11.0.6-r1"
package_supported_version="1.16"

# Global constants
patched_file_comment='experimental version of ${CATEGORY}/${PN}'


cd "${script_folder%/tools}"

# Import function declarations
. "tools/common-functions.sh"


# Remove unneeded patch/conf files
cd "${script_folder%/tools}/files"
rm	xorg-server-1.12-cve-*.patch \
	xorg-server-1.17-cve-2015-0255*.patch \
	xorg-server-1.12-disable-acpi.patch \
		2>/dev/null

# Rename and patch all the stock mesa ebuild files
cd "${script_folder%/tools}"

# Remove Changelogs - as this is an unofficial package
rm ChangeLog* 2>/dev/null


# Remove all obsolete ebuild files
declare -a array_ebuilds
for ebuild_file in *.ebuild; do
	# Don't process ebuild files twice!
	if grep -q "{patched_file_comment}" "${ebuild_file}" ; then
		continue
	fi
	
	if [[ $(compare_ebuild_versions "xorg-server-${package_supported_version}" "${ebuild_file}") -eq 1 ]] ; then
		echo "removing ebuild file: \"${ebuild_file}\" (unsupported)"
		rm "${ebuild_file}"
		continue
	fi
	
	remove_obsolete_ebuild_revisions "${ebuild_file}"
done

# Process all remaining ebuild files
for old_ebuild_file in *.ebuild; do
	# Don't process ebuild files twice!
	if grep -q "{patched_file_comment}" "${old_ebuild_file}" ; then
		continue
	fi
	
	ebuild_file=$(increment_ebuild_revision "${old_ebuild_file}")
	new_ebuild_file="${ebuild_file}.new"
	echo "Processing ebuild file: \"${old_ebuild_file}\" -> \"${ebuild_file}\""
	mv "${old_ebuild_file}" "${ebuild_file}"
	awk -F '[[:blank:]]+' \
			-veselect_opengl_supported_version="${eselect_opengl_supported_version}" \
			-vmesa_supported_version="${mesa_supported_version}" \
			--file "tools/common-functions.awk" \
			--file "tools/${script_name%.*}.awk" \
			"${ebuild_file}" 1>"${new_ebuild_file}" 2>/dev/null
		[ -f "${new_ebuild_file}" ] || exit 1
		mv "${new_ebuild_file}" "${ebuild_file}"
		new_ebuild_file="${new_ebuild_file%.new}"
done

# Rebuild the master package Manifest file
[ -n "${new_ebuild_file}" ] && [ -f "${new_ebuild_file}" ] && ebuild "${new_ebuild_file}" manifest
