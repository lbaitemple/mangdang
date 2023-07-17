# Mac specific, edit to suit your needs
cd /Volumes/systemboot/

# Enable ssh
touch ssh

# Append dtoverlay=dwc2 to config.txt
if ! grep -Fxq "dtoverlay=dwc2,dr_mode=peripheral" config.txt
then
    echo "dtoverlay=dwc2,dr_mode=peripheral" >> config.txt
fi

# Append modules-load=dwc2,g_ether after rootwait
python3 -c 'if not "modules-load=dwc2,g_ether" in open("cmdline.txt", "r").read(): c = "rootwait modules-load=dwc2,g_ether".join(open("cmdline.txt", "r").read().split("rootwait")); open("cmdline.txt", "w").write(c)'

# Don't forget to run 'localedef -i en_US -f UTF-8 en_US.UTF-8'
