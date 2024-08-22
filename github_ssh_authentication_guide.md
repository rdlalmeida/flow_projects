# How to configure github.com and a linux terminal to prevent git from requesting a username and password (the ssh agent automatically provides a key when needed)

## 1. Generate a pair of asymmetrical SSH encryption keys
List any keys present in your local (Linux) machine


	$ ls -al ~/.ssh
	
If the system complains that it cannot find a '~./ssh' folder it means for sure that no SSH keys were created yet (which is OK) but it can also mean that OpenSSL (which provides the ssh command, as well as the ssh agent and so on) is not yet installed. Confirm this with either:
	
	$ whereis ssh

or
	
	$ whereis openssl

If the system cannot find any of these executables, install OpenSSL using:
	
	$ sudo apt-get install openssl

## 2. Generate a pair of asymmetrical encryption keys in the local machine (Linux)

	$ ssh-keygen -t ed25519 -C "<github_login_email_address>"

**IMPORTANT** This key must be created with the email used for logging in the github server

If it doesn't exist yet, this command creates a $HOME/.ssh folder and, in it, two files:
	- id_ed25519, the private key of the pair
	- id_ed25519.pub the public counterpart

You can see the actual key by printing the file contents:

	$ cat id_ed25519

## 3. Add the private key to the SSH agent to be provided automatically whenever git requires it

First, ensure that the SSH agent is active and turn it on if it doesn't

	$ eval "$(ssh-agent -s)"

And then add the private key to it

	$ sudo ssh-add ~/.ssh/id_ed25519

## 4. Add the public key to your github account settings

4.1. Copy the contents of the public key file by printing or opening the key file, and copying the string that starts with *ssh-ed25519* and ends with the email used to setup the key.

4.2. Open [github.com](https://github.com) and login into your account.

4.3. Click on the profile picture in the top right corner to open the profile menu and select *Settings*

4.4. Select *SSH and GPG keys* from the menu on the left

4.5. Click on *New SSH key* green button on the upper right corner

4.6. Add a title to the key and past the public key file contents inside the *Key* field. Click on the green button on the bottom, *Add SSH key* to save the new key

**DONE. You can do authenticated operations in your Linux machine from now on (git should not ask for credentials)**



