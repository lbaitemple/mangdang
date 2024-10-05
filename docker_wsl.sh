# update system
sudo apt-get update 

# install deps
sudo apt-get install ca-certificates curl gnupg lsb-release 

# import gpg
sudo mkdir -p /etc/apt/keyrings 

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg 

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null 

sudo apt-get update 

# install docker
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin 

# start docker service
sudo service docker start 

sudo groupadd docker 

sudo usermod -aG docker $USER 

content="[boot]
command=\"service docker start\""

 echo "$content" | sudo tee -a /etc/wsl.conf > /dev/null

