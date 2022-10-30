It is all about 802.1x file 
All steps are taken from following link... Thanks to this website..

https://www.personal-privacy.com/2019/09/strong-home-wifi-protection.html

Steps for certificate generation on Radius server

**Step 1: Installing Free-Radius on Ubuntu**
		First, install the package using
	
	apt-get -y install freeradius nano /etc/freeradius/3.0/radiusd.conf

and change the followings

	proxy_requests = no
Then
	nano /etc/freeradius/3.0/clients.conf
comment this entire section (by adding a # to the start of each line)
	client localhost { … }
	
and edit the following lines (at the end of the file)
	
client your_router_name {
  ipaddr = 192.168.1.1
  secret = password
  require_message_authenticator = yes
  limit {
   lifetime = 0
    idle_timeout = 432000
  }
}

Here, you can use whatever name you want for the router, but you need the IP address of your router. Also, you need to create a password for this router and later enter it in the router setting page (we will get to that later). After finding the address, replace the one above with this address.
Next, edit

	nano /etc/freeradius/3.0/mods-available/eap
	
First, comment everything in md5, leap, gtc, ttls, peap and mschapv2 sections.
Then, in tls-config section, make sure to only have these settings:


tls-config tls-common {
   private_key_password = 'Passphrase'
   private_key_file = ${certdir}/server.pem
   
   certificate_file = ${certdir}/server.pem
   
   ca_file = ${cadir}/ca.pem
   dh_file = ${certdir}/dh
   ca_path = ${cadir}
   cipher_list = "HIGH"
   cipher_server_preference = yes
   ecdh_curve = "prime256v1"
   verify {
    tmpdir = /var/tmp/radiusd
    client = "/usr/bin/openssl verify -CAfile /etc/freeradius/3.0/certs/ca.pem %{TLS-Client-Cert-Filename}"


The 'Passphrase' here is your certificate's secret passphrase. You will need to choose one and later use it when creating your certificates.
In tls section, only
tls = tls-common
should be uncommented.
Next, run these commands
mkdir /var/tmp/radiusd
chown freerad /var/tmp/radiusd
chgrp freerad /var/tmp/radiusd
chmod 700 /var/tmp/radiusd
cd /etc/freeradius/3.0/sites-enabled/
rm *
cd /etc/freeradius/3.0/sites-available/
cp default your_router_name
nano your_router_name
Here, comment out everything except preprocess, eap, expiration, and logintime from the authorize section. Comment out everything but eap from the authenticate section.
Next
cd /etc/freeradius/3.0/sites-enabled/
ln -s ../sites-available/your_router_name .



**Step 2: Creating Certificates**
Next step is to create certificates to connect to your WiFi.
apt-get install -y make
cd /etc/freeradius/3.0/certs/
rm *.pem
rm *.key
mkdir /var/certs
mkdir /var/certs/freeradius
chgrp ssl-cert /var/certs/freeradius
chmod 710 /var/certs/freeradius
cp /usr/share/doc/freeradius/examples/certs/* /var/certs/freeradius/
cd /var/certs/freeradius/
rm bootstrap
chmod 600 *
make destroycerts
make index.txt
make serial
You need to create a secret passphrase in order to sign and use your certificates. This is the same passphrase you needed for /etc/freeradius/3.0/mods-available. This passphrase must be repeated in three files: ca.cnf, server.cnf and client.cnf in input_password and output_password fields. You need to provide this passphrase whenever you want to add your certificate to a new device as well.
Next, edit:
nano /var/certs/freeradius/ca.cnf
Change 'default_bits' from 2048 to at most 4096.
Change 'default_days' to 3650.
Change output_password and input_password to the phrase you used in eap.
In [certificate_authority] section, change the commonName to something you remember.
The rest are optional! The certificate authority section must match in all three files (server.cnf, ca.cnf and client.cnf).
Then, run
make ca.pem
make ca.der
Edit:
nano /var/certs/freeradius/server.cnf
and make the same changes here. Then, run:
make server.pem
The last file to edit is:
nano /var/certs/freeradius/client.cnf
Here, you need to choose a username in [client] section. The rest should match the ca.cnf.
Before making the client files, edit Makefile
nano /var/certs/freeradius/Makefile
In client section, add these lines:
client.p12: client.crt
    openssl pkcs12 -export -in client.crt -inkey client.key -out client.p12 -passin pass:$(PASSWORD_CLIENT) -passout pass:$(PASSWORD_CLIENT)
    cp client.p12 $(USER_NAME).p12
client.pem: client.p12
    openssl pkcs12 -in client.p12 -out client.pem -passin pass:$(PASSWORD_CLIENT) -passout pass:$(PASSWORD_CLIENT)
    cp client.pem $(USER_NAME).pem
Make sure indented lines are 'tabs' and not 'spaces'!
make client.pem
chmod 600 *
chmod 640 ca.pem
chmod 640 server.pem
chmod 640 server.key
chgrp ssl-cert ca.pem
chgrp ssl-cert server.pem
chgrp ssl-cert server.key
cd /etc/freeradius/certs/
ln -s /var/certs/freeradius/ca.pem ca.pem
ln -s /var/certs/freeradius/server.pem server.pem
ln -s /var/certs/freeradius/server.key server.key
To generate a new certificate for a new client (another person in your household or another device), you need to change the name of the client in client.cnf anf re-run the first three lines (starting from make client.pem)
Free-Radius needs to communicate through a specific port and the default is 1812. Change the firewall rule to allow this:
ufw allow 1812
ufw disable && ufw enable


**Step 3: Setting up your router**
After setting up your Free-Radius server, you need to tell your router about it. Each router has a different setup, so I cannot cover all of them here. For a TP-Link Archer C5400, go to Advanced, then Wireless. In Security field, choose WPA/WPA2-Enterprise. For RADIUS Server IP, enter the IP address of your server (if you don't know it, simply run ip -a on your server). For RADIUS Port, enter 1812 and in RADIUS password, enter the password you chose in /etc/freeradius/3.0/clients.conf file.

Importing your certificate to a Windows Client
Now that you have created your certificates, you need to import them to any device you want to connect to your WiFi. For Windows 10, follow these steps. The files you need are ca.der and client.p12 located at /var/certs/freeradius.
First, double-click on ca.der file and install the certificate on Local Computer and select "Trusted Root Certification Authorities". Do the same for client.p12, but now install it for Current User and let windows select the location automatically.
Finally, go to Network and Sharing Center, click on Set up a new connection or network, and select Manually connect to a wireless network. In the new window, enter the name of the network and choose WPA2-Enterprise as Security Type. Then go to Change Connection Settings, go to Security tab and choose Smart Card or Other Certificate and click setting. Then, on When Connecting select Advanced, tick Certificate Issuer and select your certificate (this is the commonName you chose in [certificate authority] section). Click OK, and on the previous windows, under Verify the server’s identity … choose the certificate again.




