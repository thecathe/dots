#!/usr/bin/env bash

# Find the configured esp
esp=$(bootctl -p)

# Prepare the efi partition for kernel-install
machineid=$(cat /etc/machine-id)
if [[ ${machineid} ]]; then
    mkdir ${esp}/${machineid}
else
    echo "Failed to get the machine ID"
fi

# Run kernel install for all the installed kernels
while read -r kernel; do
    kernelversion=$(basename "${kernel%/vmlinuz}")
    echo "Installing kernel ${kernelversion}"
    kernel-install add ${kernelversion} ${kernel}
done < <(find /usr/lib/modules -maxdepth 2 -type f -name vmlinuz)
