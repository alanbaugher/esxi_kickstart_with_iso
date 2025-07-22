#!/bin/bash
########################################################################################
#
#  Build a custom ESXi ISO with embedded Kickstart (KS.CFG) for automated installs
#
#  - Works with official ESXi ISO downloads from VMware
#  - Injects Kickstart into ISO root
#  - Modifies BOOT.CFG (both BIOS and UEFI) to reference Kickstart
#  - Adds verbose logging flags for install-time visibility
#  - Validates ISO contents before completion
#
#  Reference: https://williamlam.com/2023/02/automated-esxi-installation-with-a-usb-network-adapter-using-kickstart.html
#
########################################################################################

set -euo pipefail

### === CONFIGURATION ===
ESXI_ISO_ORIG="VMware-VMvisor-Installer-8.0U3-24022510.x86_64.iso"
CUSTOM_ISO="custom-esxi-ks.iso"
WORKDIR="esxi-iso"
KSFILE="ks.cfg"
KS_DEST="KS.CFG"
BOOTCFG_FILE="BOOT.CFG"

### === Check requirements ===
for cmd in 7z xorriso; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "❌ Missing required tool: $cmd"
    exit 1
  fi
done

### === Validate Inputs ===
if [ ! -f "$ESXI_ISO_ORIG" ]; then
  echo "❌ Error: ISO '$ESXI_ISO_ORIG' not found!"
  exit 1
fi

if [ ! -f "$KSFILE" ]; then
  echo "❌ Error: Kickstart file '$KSFILE' not found!"
  exit 1
fi

### === Extract ISO ===
echo "📦 Extracting ISO..."
rm -rf "$WORKDIR" "$CUSTOM_ISO"
mkdir -p "$WORKDIR"
7z x "$ESXI_ISO_ORIG" -o"$WORKDIR" >/dev/null

### === Inject Kickstart File ===
echo "📥 Adding kickstart file as '$KS_DEST'..."
cp "$KSFILE" "$WORKDIR/$KS_DEST"

### === Patch BOOT.CFG files (BIOS and UEFI boot paths) ===
BOOTCFG1_PATH="$WORKDIR/$BOOTCFG_FILE"
BOOTCFG2_PATH="$WORKDIR/EFI/BOOT/$BOOTCFG_FILE"

#KERNEL_LINE="kernelopt=runweasel ks=cdrom:/$KS_DEST allowLegacyCPU=true debugLogToSerial=TRUE loglevel=verbose"
KERNEL_LINE="kernelopt=runweasel ks=usb:/$KS_DEST allowLegacyCPU=true debugLogToSerial=TRUE loglevel=verbose"

for BOOTCFG in "$BOOTCFG1_PATH" "$BOOTCFG2_PATH"; do
  if [ -f "$BOOTCFG" ]; then
    echo "✏️ Patching $BOOTCFG..."
    sed -i.bak '/^kernelopt=/d' "$BOOTCFG"
    echo "$KERNEL_LINE" >> "$BOOTCFG"
    echo "✅ Updated kernelopt in: $BOOTCFG"
    grep '^kernelopt=' "$BOOTCFG"
  else
    echo "⚠️  $BOOTCFG not found — skipping."
  fi
done

### === Rebuild ISO ===
echo "💿 Rebuilding bootable UEFI ISO..."
pushd "$WORKDIR" >/dev/null
xorriso -as mkisofs \
  -relaxed-filenames -J -R -o "../$CUSTOM_ISO" \
  -e EFIBOOT.IMG \
  -no-emul-boot \
  .
popd >/dev/null

### === Validate Output ===
echo "🔍 Validating custom ISO..."
KS_CHECK=$(7z l "$CUSTOM_ISO" | grep -i "$KS_DEST" || true)
BOOTCFG_CHECK=$(7z x -so "$CUSTOM_ISO" "$BOOTCFG_FILE" 2>/dev/null | grep -i 'ks=' || true)

if [[ -n "$KS_CHECK" ]]; then
  echo "✅ $KS_DEST found in ISO root"
else
  echo "❌ Kickstart file not found in ISO!"
fi

if [[ -n "$BOOTCFG_CHECK" ]]; then
  echo "✅ Kickstart kernelopt reference present in boot config"
else
  echo "❌ Validation failed: BOOT.CFG does not contain Kickstart reference!"
fi

### === Final Instructions ===
echo ""
echo "🎉 Done. Custom ISO: $CUSTOM_ISO"
echo "👉 Use Rufus to flash using FAT32 + GPT or MBR (UEFI recommended)"
echo "💡 Tip: If you want to override the Kickstart location at boot, press Shift+O and enter:"
echo "    ks=usb:/KS.CFG"
echo "✅ Make sure your USB stick contains the KS.CFG in its root if you use the USB method."

