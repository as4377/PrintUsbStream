#!/usr/bin/env bash

echo "Envronment Setup for Radio Serial Printing"

echo "Checking if git is installed..."
if command -v git > /dev/null 2>&1; then
  echo "Git is installed, going to next step" 
else
    echo "Git is not installed" 
    echo "Installing git..."
    sudo apt install git
fi

echo "Cloning down the script repository"
if [ ! -d "/home/$USER/RadioSerialPrinter" ]
then
    mkdir /home/$USER/RadioSerialPrinter
    pushd /home/$USER/RadioSerialPrinter
    git clone https://github.com/as4377/PrintUsbStream.git
    popd
fi

echo "Setting up the printing environment"
if command -v cups > /dev/null 2>&1; then
    echo "Cups is installed, going to next step"
else
    echo "Cups in not installed"
    echo "Installing cups..."
    sudo apt install cups
fi

echo "Configuring usermod..."
sudo usermod -a -G lpadmin $USER

echo "Setting up chromium"
if command -v chromium-browser > /dev/null 2>&1; then
    echo "Chromium is installed, going to next step"
else
    echo "Chromium is not installed"
    echo "Installing chromium..."
    sudo apt install chromium-browser
fi

echo "Converting Script to Service"

if [ -f "/etc/systemd/system/USB_Radio.service" ]; then
    #remove version of the service
    sudo rm /etc/systemd/system/USB_Radio.service
    #TODO find and kill previous version of service if there is one
fi
#Start file creation
touch ./USB_Radio.service

echo "[Unit]" >> USB_Radio.service
echo "Description=Prints input off of a serial connection " >> USB_Radio.service
echo "After=network.target" >> USB_Radio.service
echo "" >>USB_Radio.service
echo "[Service]" >> USB_Radio.service
echo "Type=forking" >> USB_Radio.service
echo "ExecStart=/usr/bin/python3 /home/$USER/RadioSerialPrinter/PrintUsbStream/serial_reader.py" >> USB_Radio.service
echo "TimeoutStartSec=0" >> USB_Radio.service
echo "" >>USB_Radio.service
echo "[Install]" >> USB_Radio.service
echo "WantedBy=default.target" >> USB_Radio.service
#end file creation 

echo "Setting up service to run on reboot"
sudo mv ./USB_Radio.service /etc/systemd/system
sudo systemctl daemon-reload
sudo systemctl enable USB_Radio.service
#check if service was created
if systemctl -all|grep -q USB_Radio; then
    echo "Service created"
else
    echo "Service creation failed, please rerun the script"
    exit
fi

sudo systemctl start USB_Radio.service &
#check if service is running
if systemctl is-active --quiet USB_Radio; then
    echo "Failed to start service, please rerun the set up script"
    exit 1
else
    echo "Service is created and running"
fi


echo "Please set up the printer.."
chromium-browser http://localhost:631/admin &

echo "Once printer setup is complete please execute StartPrintingService.sh"