#!/bin/bash
HOST=ftp.swuthoughts.ca
echo "Remember, there's a password complexity rule"

read -s -p "User:" USER
read -s -p "Password:" PASSWORD

ncftp -u $USER@swuthoughts.ca -p $PASSWORD $HOST <<EOF 
put -r blog/* ./grav/user/pages/blogs
bye
EOF


