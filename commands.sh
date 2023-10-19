#!/bin/bash

set -e

# --- Master Node ---

vagrant ssh master <<EOF
    # Create and configure 'altschool' user
    sudo useradd -m -G sudo altschool
    echo -e "alt\nalt\n" | sudo passwd altschool 
    sudo usermod -aG root altschool
    sudo useradd -ou 0 -g 0 altschool,
    
    # Generate SSH key for 'altschool'
    sudo -u altschool ssh-keygen -t rsa -b 4096 -f /home/altschool/.ssh/id_rsa -N "" -y
    
    # Generate SSH key for 'vagrant'
    sudo ssh-keygen -t rsa -b 4096 -f /home/vagrant/.ssh/id_rsa -N ""
    
    # Allow 'vagrant' to connect to the second node
    sudo cat /home/altschool/.ssh/id_rsa.pub | sshpass -p "vagrant" ssh -o StrictHostKeyChecking=no vagrant@192.168.20.11 'mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys'
    
    # Allow 'vagrant' to connect to the second node using 'altschool' key
    sudo cat ~/altschoolkey | sshpass -p "vagrant" ssh vagrant@192.168.20.11 'mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys'    
    sudo chmod 700 ~/.ssh
    sudo chmod 600 ~/.ssh/authorized_keys

    # Create directory on the second node
    sshpass -p "alt" sudo -u altschool mkdir -p /mnt/altschool/slave
    sudo chmod +r /mnt/altschool/slave

    # Copy contents to the second node
    sshpass -p "alt" sudo -u altschool scp -r /mnt/* vagrant@192.168.20.11:/mnt/altschool/slave
    
    # Save running processes
    sudo ps aux > /home/vagrant/running_processes
    
    exit
EOF

# --- Master and Slave Nodes ---

# For both Master and Slave Nodes
for NODE in "master" "slave"; do
    vagrant ssh $NODE <<EOF

        # Update and upgrade packages
        sudo apt update -y
        sudo apt upgrade -y

        # Install and configure Apache, MySQL, PHP
        sudo apt install -y apache2 mysql-server php libapache2-mod-php php-mysql
        
        # Firewall rules for Apache
        sudo ufw allow in "Apache"
        sudo ufw status
        
        # Adjust permissions for /var/www
        sudo chown -R www-data:www-data /var/www
        
        # Enable modules
        sudo a2enmod rewrite
        sudo phpenmod mcrypt
        
        # Configure directory index
        sudo sed -i 's/DirectoryIndex index.html index.cgi index.pl index.xhtml index.htm/DirectoryIndex index.php index.html index.cgi index.pl index.xhtml index.htm/' /etc/apache2/mods-enabled/dir.conf
        
        # Add PHP info file
        echo "<?php phpinfo(); ?>" | sudo tee /var/www/html/index.php

        # Restart Apache
        sudo systemctl reload apache2

        # Install and configure Apache, MySQL, PHP
        sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password alt'
        sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password alt'

        # Securing MySQL installation
        echo "Securing MySQL installation..."
        sudo mysql_secure_installation <<EOF2
        y
        alt
        alt
        y
        y
        y
        y

        echo -e "\n\nLAMP Installation Completed"
       
        exit 0
EOF
done

# --- Master Node ---

vagrant ssh master <<EOF
    
    # Install and configure Nginx as a load balancer
    sudo apt install -y nginx

    # Create a custom Nginx configuration file for load balancing
    echo "
    upstream backend {
        server 192.168.20.10; # IP of master node
        server 192.168.20.11; # IP of slave node
    }

    server {
        listen 80;

        location / {
            proxy_pass http://backend;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        }
    }
    " | sudo tee /etc/nginx/sites-available/load_balancer.conf

    # Enable the new configuration and restart Nginx
    sudo ln -s /etc/nginx/sites-available/load_balancer.conf /etc/nginx/sites-enabled/
    sudo systemctl restart nginx

    exit
EOF
