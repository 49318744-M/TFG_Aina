#!/bin/bash
# Install pip
sudo apt update
sudo apt install -y python3-pip python3.12-venv

# Install Docker
# https://docs.docker.com/engine/install/ubuntu/
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker $USER

# Install CUDA toolkit and container toolkit
# https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html
sudo apt install -y nvidia-cuda-toolkit
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit
sudo apt install -y nvidia-utils-535
sudo apt install -y nvidia-driver-535
sudo apt install -y nvidia-container-runtime
sudo tee /etc/docker/daemon.json > /dev/null <<EOL
{
  "default-runtime": "nvidia",
  "runtimes": {
    "nvidia": {
      "path": "nvidia-container-runtime",
      "runtimeArgs": []
    }
  }
}
EOL

# Install libcudart11.0
# https://developer.nvidia.com/cuda-11.0-download-archive?target_os=Linux
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/cuda-ubuntu2004.pin
sudo mv cuda-ubuntu2004.pin /etc/apt/preferences.d/cuda-repository-pin-600
wget http://developer.download.nvidia.com/compute/cuda/11.0.2/local_installers/cuda-repo-ubuntu2004-11-0-local_11.0.2-450.51.05-1_amd64.deb
sudo dpkg -i cuda-repo-ubuntu2004-11-0-local_11.0.2-450.51.05-1_amd64.deb
sudo apt-key add /var/cuda-repo-ubuntu2004-11-0-local/7fa2af80.pub
sudo apt-get update
sudo apt-get -y install cuda
rm cuda-repo-ubuntu2004-11-0-local_11.0.2-450.51.05-1_amd64.deb

# Install AWS CLI
# https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
sudo apt install -y unzip
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm awscliv2.zip

# Install Anaconda dependencies and Anaconda itself
# https://docs.anaconda.com/free/anaconda/install/linux/
sudo apt-get install -y libgl1-mesa-glx libegl1-mesa libxrandr2 libxrandr2 libxss1 libxcursor1 libxcomposite1 libasound2 libxi6 libxtst6
curl -O https://repo.anaconda.com/archive/Anaconda3-2024.02-1-Linux-x86_64.sh
sudo bash Anaconda3-2024.02-1-Linux-x86_64.sh -b -p $HOME/anaconda3
echo 'export PATH="$HOME/anaconda3/bin:$PATH"' >> ~/.bashrc
rm Anaconda3-2024.02-1-Linux-x86_64.sh
sudo chown -R ubuntu:ubuntu /home/ubuntu/anaconda3
source ~/.bashrc

# Create a virtual environment
conda update -n base -c defaults conda -y
conda create -n monai python=3.8 pytorch torchvision cudatoolkit=11.0 -c pytorch -c conda-forge --yes
conda init bash
exec $SHELL
conda activate monai
pip install monai-deploy-app-sdk scikit-image matplotlib holoscan gdown
sudo reboot