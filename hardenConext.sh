#! /bin/bash

# Name of the new user to be created
# This user is used for login with ssh key and will get SUDO rights
username=OpenConext

# SSH port
# The port to set sshd to
sshdport=22


# * Remove/Disable some stuff from default install*

# CUPS
echo "Removing CUPS and dependencies"
yum remove cups –remove-leaves -y

# GUI
# Do not allow GUI mode to be started
echo "Disableing GUI startup in /etc/inittab"
sed -i 's/^id:5:initdefault:/id:3:initdefault:/g' /etc/inittab

# Disable and remove ZEROCONF
# Edit /etc/sysconfig/network
echo "Disable and remove ZEROCONF"
echo "NOZEROCONF=yes" >> /etc/sysconfig/network
yum remove avahi

# * Remove wireless modules
echo "Remove wireless modules"
for i in $(find /lib/modules/`uname -r`/kernel/drivers/net/wireless
-name "*.ko" -type f) ; do echo blacklist $i >>
/etc/modprobe.d/blacklist-wireless ; done

# *Users and Passwords*
echo "Have centos use SHA512 for password hashing"
authconfig --passalgo=sha512 --update
echo "set umask of 077"
perl -npe 's/umask\s+0\d2/umask 077/g' -i /etc/bashrc
perl -npe 's/umask\s+0\d2/umask 077/g' -i /etc/csh.cshrc

echo "Using pam_tally2 to restrict the number of login attempts"
echo "The file /var/log/tallylog is a binary log containing failed login
records for pam."
echo "You can see the failed attempts by running the pam_tally2 command
without any options, "
echo "and unlock user accounts early by using pam_tally2 --reset -u
username"
#
touch /var/log/tallylog
 /etc/pam.d/system-auth
#%PAM-1.0
# This file is auto-generated.
# User changes will be destroyed the next time authconfig is run.
auth        required      pam_env.so
auth        sufficient    pam_unix.so nullok try_first_pass
auth        requisite     pam_succeed_if.so uid >= 500 quiet
auth        required      pam_deny.so
auth        required      pam_tally2.so deny=3 onerr=fail unlock_time=60

account     required      pam_unix.so
account     sufficient    pam_succeed_if.so uid < 500 quiet
account     required      pam_permit.so
account     required      pam_tally2.so per_user

password    requisite     pam_cracklib.so try_first_pass retry=3
minlen=9 lcredit=-2 ucredit=-2 dcredit=-2 ocredit=-2
password    sufficient    pam_unix.so sha512 shadow nullok
try_first_pass use_authtok remember=10
password    required      pam_deny.so

session     optional      pam_keyinit.so revoke
session     required      pam_limits.so
session     [success=1 default=ignore] pam_succeed_if.so service in
crond quiet use_uid
session     required      pam_unix.so
EOF

# Logout idle users after 15 min.
echo "Idle users will be removed after 15 minutes"
echo "readonly TMOUT=900" >> /etc/profile.d/os-security.sh
echo "readonly HISTFILE" >> /etc/profile.d/os-security.sh
chmod +x /etc/profile.d/os-security.sh

# Restict usage of CRON and AT
echo "Locking down Cron"
touch /etc/cron.allow
chmod 600 /etc/cron.allow
awk -F: '{print $1}' /etc/passwd | grep -v root > /etc/cron.deny
echo "Locking down AT"
touch /etc/at.allow
chmod 600 /etc/at.allow
awk -F: '{print $1}' /etc/passwd | grep -v root > /etc/at.deny


* Root account *
echo "Creating a strong passwd for the ROOT user"
root_pass=$(cat /dev/urandom| tr -dc 'a-zA-Z0-9-_!@#$%^&*()_+{}|:<>?='|fold -w 30| head -n 1)
echo "The new ROOT password is: " $pass
echo $pass | passwd --stdin root

echo "Adding OpenConext user with strong password"
pass=$(cat /dev/urandom| tr -dc 'a-zA-Z0-9-_!@#$%^&*()_+{}|:<>?='|fold -w 30| head -n 1)
echo "Username: " $username
echo "Password: " $pass
useradd -m -p $pass $username

echo "Set up Sudo for user OpenConext"
yum install -y sudo
echo "Adding OpenConext to Sudoers"
echo "OpenConext    ALL=(ALL)       ALL" >> /etc/sudoers

# Make sure the user sets up a ssh key login
echo "After this step, SSH will be configured to use ssh key login for
the OpenConext user only."
echo "Therefor you should create a new key ON YOUR CLIENT"
echo " Execute the following:"
echo "ssh-keygen -f ~/.ssh/id_rsa_$username"
echo "ssh-copy-id -i ~/.ssh/id_rsa_$username.pub $username@"



echo "Setup SSH: No root login, port $sshdport, use keys for login only"
cat << 'EOF' >> /etc/ssh/sshd_config
#=======================================================#
#
# Section below was added by OpenConext Hardening
#
#=======================================================#
# Set sshd to use port $sshdport
Port $sshdport
# No root login
PermitRootLogin no
# no passwd login, only use certificates
PasswordAuthentication no
ChallengeResponseAuthentication no
UsePAM no
X11Forwarding no
GSSAPIAuthentication no

echo "Set up NTP"
touch /etc/cron.daily/ntpdate
echo '#!/bin/sh' >> /etc/cron.daily/ntpdate
echo '/usr/sbin/ntpdate 0.europe.pool.ntp.org' >> /etc/cron.daily/ntpdate
chmod a+x /etc/cron.daily/ntpdate



echo "Fixing network config"
# /etc/sysctl.conf settings

cat << 'EOF' >> /etc/sysctl.conf
#=======================================================#
#
# Section below was added by OpenConext Hardening
#
#=======================================================#
# Don't reply to broadcasts. Prevents joining a smurf attack
net.ipv4.icmp_echo_ignore_broadcasts = 1
# Enable protection for bad icmp error messages
net.ipv4.icmp_ignore_bogus_error_responses = 1
# Enable syncookies for SYN flood attack protection
net.ipv4.tcp_syncookies = 1
# Log spoofed, source routed, and redirect packets
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1
# Don't allow source routed packets
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
# Turn on reverse path filtering
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
# Don't allow outsiders to alter the routing tables
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
# Don't pass traffic between networks or act as a router
net.ipv4.ip_forward = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
EOF

echo "Setup IPTables in a restricted way"
cat << 'EOF' > /etc/sysconfig/iptables
#=======================================================#
#
# Section below was added by OpenConext Hardening
#
#=======================================================#
#Drop anything we aren't explicitly allowing. All outbound traffic is okay
*filter
:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT ACCEPT [0:0]
:RH-Firewall-1-INPUT - [0:0]
-A INPUT -j RH-Firewall-1-INPUT
-A FORWARD -j RH-Firewall-1-INPUT
-A RH-Firewall-1-INPUT -i lo -j ACCEPT
-A RH-Firewall-1-INPUT -p icmp --icmp-type echo-reply -j ACCEPT
-A RH-Firewall-1-INPUT -p icmp --icmp-type destination-unreachable -j ACCEPT
-A RH-Firewall-1-INPUT -p icmp --icmp-type time-exceeded -j ACCEPT
# Accept Pings
-A RH-Firewall-1-INPUT -p icmp --icmp-type echo-request -j ACCEPT
# Log anything on eth0 claiming it's from a local or non-routable network
# If you're using one of these local networks, remove it from the list below
-A INPUT -i eth0 -s 10.0.0.0/8 -j LOG --log-prefix "IP DROP SPOOF A: "
-A INPUT -i eth0 -s 172.16.0.0/12 -j LOG --log-prefix "IP DROP SPOOF B: "
-A INPUT -i eth0 -s 192.168.0.0/16 -j LOG --log-prefix "IP DROP SPOOF C: "
-A INPUT -i eth0 -s 224.0.0.0/4 -j LOG --log-prefix "IP DROP MULTICAST D: "
-A INPUT -i eth0 -s 240.0.0.0/5 -j LOG --log-prefix "IP DROP SPOOF E: "
-A INPUT -i eth0 -d 127.0.0.0/8 -j LOG --log-prefix "IP DROP LOOPBACK: "
# Accept any established connections
-A RH-Firewall-1-INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
# Accept ssh traffic on port $sshdport.
# Allow traffic from well know SURFnet networks only
-A RH-Firewall-1-INPUT -s 192.87.109.0/24 -m state --state NEW -m tcp -p tcp --dport $sshdport -j ACCEPT
-A RH-Firewall-1-INPUT -s 192.87.118.0/24 -m state --state NEW -m tcp -p tcp --dport $sshdport  -j ACCEPT
-A RH-Firewall-1-INPUT -s 195.169.126.0/24 -m state --state NEW -m tcp -p tcp --dport $sshdport -j ACCEPT
-A RH-Firewall-1-INPUT -s 83.83.85.239 -m state --state NEW -m tcp -p tcp --dport $sshdport -j ACCEPT
# Accept https traffic. Restrict this to known ips if possible.
# Allow traffic from well know SURFnet networks only
-A RH-Firewall-1-INPUT -s 192.87.109.0/24 -m state --state NEW -m tcp -p tcp --dport 443 -j ACCEPT
-A RH-Firewall-1-INPUT -s 192.87.118.0/24 -m state --state NEW -m tcp -p tcp --dport 443 -j ACCEPT
-A RH-Firewall-1-INPUT -s 195.169.126.0/24 -m state --state NEW -m tcp -p tcp --dport 443 -j ACCEPT
-A RH-Firewall-1-INPUT -s 83.83.85.239 -m state --state NEW -m tcp -p tcp --dport 443 -j ACCEPT
# To allow public access to 443 use:
# -A RH-Firewall-1-INPUT -m state --state NEW -m tcp -p tcp --dport 443
-j ACCEPT

#Log and drop everything else
-A RH-Firewall-1-INPUT -j LOG
-A RH-Firewall-1-INPUT -j REJECT --reject-with icmp-host-prohibited
COMMIT
EOF


echo "Use TCP Wrappers"
echo "ALL:ALL" >> /etc/hosts.deny
echo "sshd:ALL" >> /etc/hosts.allow
echo "httpd:ALL" >> /etc/hosts.allow
echo "slapd:ALL" >> /etc/hosts.allow
echo "mysqld:ALL" >> /etc/hosts.allow


echo "Make sure Security Updates are installed"
# Install yum-security
yum -y install yum-security


# Information 

echo "The following services will be started: "
# Show services that may be started
chkconfig | grep on


