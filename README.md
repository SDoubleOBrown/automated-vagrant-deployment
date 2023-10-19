# automated-vagrant-deployment
## Description
  - Bashscript for the automated deployment of a Vagrant Ubuntu cluster with LAMP stack
  - Deploys two vagrant-based Ubuntu systems, designated as 'Master' and 'Slave' with an integrated LAMP stack on both systems
  - The 'Master' node acts as a control system that manages the 'Slave' node
  - A username 'altschool' with root privileges is created on the Master node and can seamlessly SSH into the Slave node without requiring       a     password
  - On initiation the contents of /mnt/altschool directory is copied from the Master node to /mnt/altschool/slave on the Slave node. This       is     performed using the altschool user from the Master node
  - The Master node displays an overview of the Linux process management, showcasing currently running processes.
  - Apache is set to start on boot, and MySQL is set to initialize with a default user and password


## Must Have:
  - Linux environment
  - Vagrant
  - Virtualbox
  - Internet access
  - Sufficient system resources
  - 
## How to use this file:
Do not skip any step. Where there is a $ symbol before a text, run the command in your Linux environment.

Step 1: you must be in a major directory either downloads, documents or music
`$ cd Documents`

Step 2: creating a new directory that holds our scripts
`$ mkdir vms`

Step 3: copy the command.sh and vagrant.sh script into the vms directory. You can do this in 2 ways:
 1 - copying the command.sh and vagrant.sh file after downloading into the vms directory using your file manager
 2 - copying the file through git bash

Step 4: making sure the scripts are executable
`$ chmod +x command.sh`
`$ chmod +x script.sh`

Step 5: running the script
You only need to run one of the script which is the vagrant.sh once that runs it will automatically run the command.sh script once done:
`$ ./vagrant.sh`

Step 6: wait until everything runs till the end

## Script Component
### Slave Node Configuration
  - The hostname is set to 'Slave' with an Ubuntu20.04LTS operating system
  - It is assigned a private network interface and is assigned a static IP "192.168.20.11"
  - There is a provisioning block to
      -  update and upgrade system packages
      -  install the sshpass package for password-based SSH authentication
      -  modify the /etc/ssh/sshd_config file password authentication option
      -  restart the SSH service to apply the changes
      -  install avahi-daemon and libnss-mdns packages for mDNS resolution
### Master Node Configuration
  - The hostname is set to 'Master' with an Ubuntu20.04LTS operating system
  - It is assigned a private network interface and is assigned a static IP "192.168.20.10"
  - There is a provisioning block to
      -  update and upgrade system packages
      -  install the sshpass package for password-based SSH authentication
      -  install avahi-daemon and libnss-mdns packages for mDNS resolution
### Creating and configuring altschool user - Master Node
  - Creates a new user 'altschool', creates a home directory for the user, and adds the user to the sudo group
  - Sets a password for the user, and adds the user to the root group.
  - Assigns a UID of 0, and a GID of 0
### Generate SSH Key for altschool user - Master Node
  - Generates a new SSH key pair for the altschool user in the path: /home/altschool/.ssh/id_rsa
  - Copies public SSH key of the altschool user to the authorized keys file of the vagrant user on the Slave node
  - Sets permission for the ~/.ssh directory and authorized_keys file
### Creates directory on slave node and copies contents - Master Node
  - Creates a /mnt/altschool/slave directory on the slave node
  - Grants read permission
  - Copies content of /mnt directory on the master node to /mnt/altschool/slave on the slave node
### Save running processes - Master Node
  - Captures a list of all currently running processes along with their details
  - The output is then redirected running_processes in the /home/vagrant directory
### Installing LAMP on both nodes using a loop
### Update and upgrade packages
  - Updates the local package information
  - Upgrades installed packages to their latest versions
### Install and configure Apache, MySQL, PHP
  - Installs the Apache web server, MySQL database server and PHP along with the required modules for integration with Apache and MySQL
### Firewall rules for Apache
  - Allows incoming traffic on the default HTTP port used by Apache
  - Displays the current status and rules of the firewall
### Adjust permissions for /var/www
  - Changes ownership of all files and directories under /var/www to the user and group www-data:www-data
  - Ensures the web server process has the necessary permissions to read and serve files from the /var/www directory
### Enable modules
  - Enables the rewrite module in Apache. This module allows for URL rewriting
  - Enables the mcrypt extension for PHP. This extension provides cryptographic functions
### Configure directory index
  - Replaces the existing list of default index files with a new list.
  - Ensures that when a directory is requested, Apache will first look for index.php before falling back to the other files in the list
