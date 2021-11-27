#!/usr/bin/env bash
# OpenTabletDriver udev rules generator, written in bash
version=1.0
install=0
idk=0
tput=0

# Colors
bold="\\e[1m"
reg="\\e[0m"
red="\\e[0;31m"
_red="\\e[1;31m"
grn="\\e[0;32m"
_grn="\\e[1;32m"
ylw="\\e[0;33m"
_ylw="\\e[1;33m"
blu="\\e[0;34m"
_blu="\\e[1;34m"

case "$1" in -h*|--h*) _exit="" ;; *) _exit="exit 1" ;; esac
if ! command -v git &>/dev/null || \
   ! command -v jq &>/dev/null; then
   echo -e "Please, make sure that you have installed ${ylw}git${reg} and ${ylw}jq${reg} and also added them to the ${_ylw}PATH${reg} variable" >&2
   $_exit
fi

if command -v tput &>/dev/null; then
	tput=1
fi
if [ "$(id -u)" -eq 0 ]; then
	sudo=()
	su=('eval')
else
	sudo=('sudo')
	su=('su' '-c')
fi

isput() {
	[ "$tput" == 1 ] && return 0 || return 1
}
trapcom() {
	echo -e "\n${red}Termination signal received.${reg}" >&2
	[ -d ./OpenTabletDriver ]          && rm -rf ./OpenTabletDriver
	[ -f ./99-opentabletdriver.rules ] && rm -f  ./99-opentabletdriver.rules
	exit 1
}
reload_udev() {
read -r -p "Reload udev rules? [Y/n] " _ques
case "$_ques" in
	""|Y*|y*)
	${sudo[*]} udevadm control --reload-rules || \
	{
		echo -e "${bold}sudo${reg} ${red}command failed, trying${reg} ${bold}su${reg}" >&2
		${su[*]} 'udevadm control --reload-rules' || \
			{
				echo -e "${bold}udev${reg} rules reload ${red}failed${reg}." >&2
				echo -e "Execute ${_ylw}udevadm control --reload-rules${reg} as ${bold}root${reg}" >&2
				exit 1
			}
	}
	echo -e "${grn}Reloaded!${reg}"
	;;
	*) :
	;;
	esac
}

if [ -z "$1" ]; then
	if [ -f ./OpenTabletDriver.Tools.udev/OpenTabletDriver.Tools.udev.csproj ]; then
		dir=.
	else
		trap trapcom SIGTERM SIGINT
		dir=./OpenTabletDriver
	fi
else
	case "$1" in
		-h*|--h*)
		echo "OpenTabletDriver udev rules generator v${version} (bash implementation)"
		echo ""
		echo "Usage: $0 [OPTION] [OTD_REPO_DIR]"
		echo ""
		echo " Options:"
		echo "  --help     Display this message"
		echo "  --install  Generate and install the created udev rules"
		echo "  --idk      Clone the whole repository of OTD and do the thing"
		echo "  --delete   Remove installed udev rules"
		echo ""
		echo "Created by github.com/BiteDasher"
		exit 0
		;;

		-i|--install)
		install=1
		if [ -z "$2" ]; then
			if [ -f ./OpenTabletDriver.Tools.udev/OpenTabletDriver.Tools.udev.csproj ]; then
				dir=.
			else
				trap trapcom SIGTERM SIGINT
				dir=./OpenTabletDriver
			fi
		else
			dir="$2"
		fi
		;;

		-idk|--idk)
		idk=1
		install=1
		rm -rf ./OpenTabletDriver
		trap trapcom SIGTERM SIGINT
		isput && echo -ne "${bold}Checking connection with${reg} ${blu}GitHub${reg}${bold}...${reg}" || echo -e "${bold}Checking connection with${reg} ${blu}GitHub${reg}${bold}...${reg}"
		if ! ping -c 1 github.com 1>/dev/null; then
			echo -e "${_red}Check your internet connection!${reg}" >&2
			exit 1
		fi
		isput && echo -ne "\r                                                                      "
		isput && echo -ne "\r${bold}Cloning...${reg}" || echo -e "${bold}Cloning...${reg}"
		git clone -q https://github.com/OpenTabletDriver/OpenTabletDriver.git OpenTabletDriver
		dir=./OpenTabletDriver
		isput && echo -ne "\r"
		;;

		-r|--remove|-d|--delete)
		if [ -f /etc/udev/rules.d/99-opentabletdriver.rules ]; then
			if ${sudo[*]} rm /etc/udev/rules.d/99-opentabletdriver.rules; then
				reload_udev
			else
				echo -e "${bold}sudo${reg} ${red}command failed, trying${reg} ${bold}su${reg}" >&2
				${su[*]} 'rm /etc/udev/rules.d/99-opentabletdriver.rules' || \
				{
					echo -e "${bold}su${reg} ${red}command failed${reg}" >&2
					exit 1
				}
				reload_udev
			fi
			echo -e "${_grn}Done!${reg}"
			exit 0
		else
			echo -e "${ylw}udev rules${reg} were not installed. Nothing to do"
			exit 0
		fi
		;;

		*)
		dir="$1"
		;;
	esac
fi

dir="$(realpath -- "$dir")"

if [[ ! -d "$dir"/OpenTabletDriver.Configurations || ! -d "$dir" ]]; then
	echo -e "Configuration files in directory '$dir' ${red}not found${reg}." >&2
	echo -e " ${bold}!${reg} Clone \e]8;;https://github.com/OpenTabletDriver/OpenTabletDriver\a\e[4mOpenTabletDriver\e[0m\e]8;;\a repository first.${reg}" >&2
	echo -e "Or, execute ${bold}$0 --idk${reg}" >&2
	exit 1
fi

_PWD="$(pwd)"
file="$_PWD/99-opentabletdriver.rules"

#####
if [ "$tput" == 1 ]; then
_fline=$(tput cuu1)
_sline=$(tput el)
_countall="$(find "$dir"/OpenTabletDriver.Configurations/Configurations -mindepth 1 | wc -l)"

for percent in 1 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100; do
	eval '__'$percent'="$((_countall * '$percent' / 100))"'
done

find_p() {
	#for percent in 1 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 80 95 100; do
	#	eval 'if [[ $_count == $__'$percent' ]]; then _current=$percent; break; fi'
	#done
	
	# Twice as fast as the method with `for'
	# shellcheck disable=SC2254
	case $_count in
		$__1)  _current=1  ;; $__5)  _current=5  ;; $__10) _current=10 ;; $__15) _current=15 ;;
		$__20) _current=20 ;; $__25) _current=25 ;; $__30) _current=30 ;; $__35) _current=35 ;;
		$__40) _current=40 ;; $__45) _current=45 ;; $__50) _current=50 ;; $__55) _current=55 ;;
		$__60) _current=60 ;; $__65) _current=65 ;; $__70) _current=70 ;; $__75) _current=75 ;;
		$__80) _current=80 ;; $__85) _current=85 ;; $__90) _current=90 ;; $__95) _current=95 ;;
		$__100) _current=100 ;;
	esac
}

fi

_count=0
#####

echo "Generating..."
echo ""
isput && echo ""
isput && echo ""

echo "# Dynamically generated from OpenTabletDriver.Configurations with the bash written tool by BiteDasher" > "$file"
echo 'KERNEL=="uinput", SUBSYSTEM=="misc", TAG+="uaccess", OPTIONS+="static_node=uinput"' >> "$file"
for vendor in "$dir"/OpenTabletDriver.Configurations/Configurations/*; do
	isput && echo -e "${_fline}${_sline}${_fline}${_sline}\c"
	echo -e "${bold}>>>${reg} ${_blu}$(basename "$vendor")${reg}"
	#####
	isput && {
		((_count++))
		find_p
		echo -e "Progress: ${_grn}$_current${reg}%"
	}
	#####
	for device in "$vendor"/*.json; do
		device_name="$(jq -M -r .Name "$device")"
		isput && echo -e "${_fline}${_sline}${_fline}${_sline}\c"
		echo -e " ${bold}->${reg} ${_ylw}$device_name${reg}"
		#####
		isput && {
			((_count++))
			find_p
			echo -e "Progress: ${_grn}$_current${reg}%"
		}
		#####
		echo "# $device_name" >> "$file"
		vendorid="$(jq -M -r .DigitizerIdentifiers[].VendorID "$device" | sort -u)"
		if [[ -z "$vendorid" ]] || (( "$(echo "$vendorid" | wc -l)" > 1 )); then
			isput && echo -e "${_fline}${_sline}${_fline}${_sline}\c"
			echo -e "${_red}Something went wrong with${reg} ${_blu}'$device_name'${reg}, ${_red}skipping${reg}..." >&2
			sleep 1
			#
			isput && {
				((_count++))
				find_p
				echo -e "Progress: ${_grn}$_current${reg}%"
			}
			#
			continue
		fi
		vendorid_hex="$(printf "%04x" "$vendorid")"
		products="$(jq -M -r .DigitizerIdentifiers[].ProductID "$device" | sort -u)"
		# 3 cycles instead of 1 to more correspond to the output of the official script in C#
		for product in $products; do
			productid_hex="$(printf "%04x" "$product")"
echo 'SUBSYSTEM=="hidraw", ATTRS{idVendor}=="'$vendorid_hex'", ATTRS{idProduct}=="'$productid_hex'", MODE="0666"' >> "$file"
		done
		for product in $products; do
			productid_hex="$(printf "%04x" "$product")"
echo 'SUBSYSTEM=="usb", ATTRS{idVendor}=="'$vendorid_hex'", ATTRS{idProduct}=="'$productid_hex'", MODE="0666"' >> "$file"
		done
		if [ "$(jq -M -r .Attributes.libinputoverride "$device")" == 1 ]; then
		for product in $products; do
			productid_hex="$(printf "%04x" "$product")"
echo 'SUBSYSTEM=="input", ATTRS{idVendor}=="'$vendorid_hex'", ATTRS{idProduct}=="'$productid_hex'", ENV{LIBINPUT_IGNORE_DEVICE}="1"' >> "$file"
		done
		fi
	done
done

isput && echo -e "${_fline}${_sline}${_fline}${_sline}\c"
echo -e "${_grn}Done${reg}${bold}!${reg}"

if [ "$install" == 1 ]; then
	echo -e "Installing ${_ylw}udev rules${reg}..."
	{
		${sudo[*]} install -D -m 644 "$file" /etc/udev/rules.d/99-opentabletdriver.rules || \
		${su[*]} 'install -D -m 644 "'$file'" /etc/udev/rules.d/99-opentabletdriver.rules'
	} && rm "$file"
	reload_udev
fi
[ "$idk" == 1 ] && rm -rf "$dir"
:
