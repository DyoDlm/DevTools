!/bin/bash

install() {
	echo && echo && echo // && echo Starting installation of $1
	echo Y | sudo apt install $1
	echo && echo // Installation completed for $1 package && echo
}

init() {
	sudo systemctl start nginx
	sudo systemctl enable nginx

	sudo ufw allow Openssh
	#	sudo ufw allow <service>
	sudo ufw enable 
	sudo ufw allow 8080
	sudo ufw allow 443
}

pkgs="\
	"vim" \
	"git" \
       	"mariadb-server" \
	"ufw" \
	"nginx"
"

repos="\
	"https://github.com/moop250/webserv.git" \
	"https://github.com/DyoDlm/PopUpForum.git" \
	"" \
	""
"

for pkg in $pkgs
do
	echo Installing $pkg ...
	install $pkg
done

for repo in $repos
do
	echo Cloning $repo repository
	git clone $repo
done

echo Init configuration ? Y/n
read -e
if [ $REPLY == "Y" ] ; then
	init
fi

#	check at : /etc/dhcpcd.conf


