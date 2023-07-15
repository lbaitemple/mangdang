# Animesh Bala Ani (ANI717)

# exit immediately if a command exits with a non-zero status.
set -e

# set default password
password='mangdang'

# record script start time
date

# install dependency
sudo apt-get update
sudo apt-get install -y python3-pip python3-setuptools curl libffi-dev
curl -sL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# install jupyterlab
sudo -H pip3 install jupyterlab
sudo -H jupyter labextension install @jupyter-widgets/jupyterlab-manager
jupyter lab --generate-config
python3 -c "from notebook.auth.security import set_password; set_password('$password', '$HOME/.jupyter/jupyter_notebook_config.json')"

# set configuration
echo "c.NotebookApp.token = ''" >> $HOME/.jupyter/jupyter_lab_config.py
echo "c.NotebookApp.password_required = True" >> $HOME/.jupyter/jupyter_lab_config.py
echo "c.NotebookApp.allow_credentials = False" >> $HOME/.jupyter/jupyter_lab_config.py

# create jupyter service
sudo cp jupyter_lab.service /etc/systemd/system/jupyter_lab.service
sudo systemctl enable jupyter_lab
sudo systemctl start jupyter_lab

# record script end time
date
