# Mount Nas drives to WSL:
- [ ]  Need to make my NAS(RMHOME-QNAP visible to WSL)
    - [ ]  make a mount point in WSL: `mkdir -p /mnt/rmhome-qnap-rohit`
    - [ ]  in powershell: `net use Z: \\RMHOME-QNAP1\Rohit`  mount QNAP\Rohit to Z:
    - [ ]  mount drive Z into WSL: `sudo mount -t drvfs Z: /mnt/rmhome-qnap-rohit`
    - [ ]  `ls -lah /mnt/rmhome-qnap-rohit/`
    - [ ]  mount the drive everytime WSL starts:
        - [ ]  Add this to `/etc/fstab`

# UNCONFIGURED FSTAB FOR BASE SYSTEM

Z: /mnt/rmhome-qnap-rohit drvfs defaults 0 0
#
