# Animesh Bala Ani (ANI717)

# exit immediately if a command exits with a non-zero status.
set -e

# set default password
password='mangdang'

# record script start time
date

# load screen
sudo apt-get install python3-pip python3-pil network-manager i2c-tools acl docker.io unzip  default-jdk git -y
sudo apt-get install libopenjp2-7 libtiff5 libatlas-base-dev -y
sudo pip3 install Adafruit_SSD1306 RPi.GPIO  Pillow notebook==6.0.0
#cp test2.sh ~/test2.sh
#cp stats.py ~/stats.py
#chmod +x ~/test2.sh
#sudo cp ipaddress.service /lib/systemd/system
#sudo systemctl daemon-reload
#sudo systemctl enable  ipaddress
#sudo systemctl start  ipaddress

# install dependency
sudo apt-get update
sudo apt-get install -y python3-pip python3-setuptools curl libffi-dev
curl -sL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# install jupyterlab
sudo -H pip3 install jupyterlab
sudo -H jupyter labextension install @jupyter-widgets/jupyterlab-manager
jupyter lab --generate-config
#python3 -c "from notebook.auth.security import set_password; set_password('$password', '$HOME/.jupyter/jupyter_notebook_config.json')"
#python3 -c "from jupyter_server.auth import passwd; print(passwd('YOUR_PASSWORD'))"
PASS_HASH=$(python3 -c "from jupyter_server.auth import passwd; print(passwd('${password}'))")
echo "c.ServerApp.password = '${PASS_HASH}'" >> $HOME/.jupyter/jupyter_lab_config.py
echo "c.ServerApp.allow_remote_access = True" >> $HOME/.jupyter/jupyter_lab_config.py

# set configuration
echo "c.NotebookApp.token = ''" >> $HOME/.jupyter/jupyter_lab_config.py
echo "c.NotebookApp.password_required = True" >> $HOME/.jupyter/jupyter_lab_config.py
echo "c.NotebookApp.allow_credentials = False" >> $HOME/.jupyter/jupyter_lab_config.py

# create jupyter service
sudo cp jupyter_lab.service /etc/systemd/system/jupyter_lab.service
sudo systemctl enable jupyter_lab
sudo systemctl start jupyter_lab

# install mangdang bsp
#cd ~
#git clone https://github.com/mangdangroboticsclub/mini_pupper_bsp
#cd mini_pupper_bsp
#./install.sh
#cd Python_Module
#sudo python3 setup.py install
# record script end time
date
