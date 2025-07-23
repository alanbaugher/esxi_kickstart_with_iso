# esxi_kickstart_with_iso


1) Download the VSphere ESXi ISO

   <img width="1800" height="1125" alt="image" src="https://github.com/user-attachments/assets/2646655a-9b8b-4948-a0c5-d3e42d049e45" />

2) Update the ks.cfg file with hostname (FQDN), Static IP address, root's password, NTP FQDN, Syslog Host (IP)

3) Run bash shell to extract and update two (2) BOOT.CFG files & copy the ks.cfg file to KS.CFG within the new ISO.
   
xorriso [ sudo dnf install xorriso ] used to update the ISO with a custom configuration ks.cfg and BOOT.CFG (2x)

<img width="991" height="706" alt="image" src="https://github.com/user-attachments/assets/aded6cb0-f696-4d48-9ab9-b4fd12fbffbb" />


4) File transfer the ISO to MS Win workstation & use Rufus (portable) to copy the updated ISO to the USB drive.

<img width="566" height="762" alt="image" src="https://github.com/user-attachments/assets/f3db151e-a98b-4e3a-9b73-35da80046a19" />

5) Place the USB drive in one of the MS-A2 USB slots and reboot the host.
   - May need to use the boot menu of the BIOS to ensure that the USB boot option is selected.

6) Confirm when ESXi installation screen displays a message should appears that the script install is progressing (with no errors).
   - There should be no required interactive effort, e.g. password, hostname, network questions.
