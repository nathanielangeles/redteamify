#!/bin/bash

# Optional: Uncomment the line below to install extra utilities
# install_extra

# Import /etc/os-release to get the system ID
if [[ -e /etc/os-release ]]; then
	source /etc/os-release
fi

# Colors
ORANGE='\033[38;2;255;165;0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
WHITE='\033[1;37m'
BANNER_RED='\033[41m'
RESET='\033[0m'

# Symbols
NOTE="${WHITE}[ 🟡 ] "
GOOD="${WHITE}[ 🟢 ] "
ERROR="${WHITE}[ 🔴 ] "

# Script information
NAME="RedTeamify"
VERSION=1.0

# System information
DISTRO="${ID}"

# Check if ran with sudo
function check_sudo() {
	if [[ $EUID -ne 0 ]]; then
		echo -e "${NOTE}Usage: sudo ${0}"
		exit 1
	fi
}

# Cool ascii banner :D
function banner() {
	echo -e "\t\t${WHITE}⠀⠀⠀⠀⣀⠤⠔⠒⠒⠒⠒⠒⠒"
	echo -e "\t\t⠀⢀⡴⠋⠀⠀⠀⠀⠀⠀⠀  "
	echo -e "\t\t⢀⠎⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ "
	echo -e "\t\t⢸⠀⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
	echo -e "\t\t⢸⠀⣇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
	echo -e "\t\t⠘⡆⢸⠀⢀⣀⣤⣄⡀⠀⠀⠀⠀"
	echo -e "\t\t⠀⠘⣾⠀⣿⣿⣿⣿⣿⠀⠀⠀⠀\t  ${RED}${NAME}${WHITE}"
	echo -e "\t\t⠀⠀⣿⠀⠙⢿⣿⠿⠃⢠⢠⡀⠀\t\t ${YELLOW}${VERSION}${WHITE}"
	echo -e "\t\t⠀⠀⠘⣄⡀⠀⠀⠀⢠⣿⢸⣿⠀"
	echo -e "\t\t⠀⠀⠀⠀⡏⢷⡄⠀⠘⠟⠈⠿⠀"
	echo -e "\t\t⠀⠀⠀⠀⢹⠸⠘⢢⢠⠤⠤⡤⠀"
	echo -e "\t\t⠀⠀⠀⠀⢸⠀⠣⣹⢸⠒⠒⡗⠀"
	echo -e "\t\t⠀⠀⠀⠀⠈⢧⡀⠀⠉⠉⠉⠉⠀"
	echo -e "\t\t⠀⠀⠀⠀⠀⠀⠉⠓⠢⠤⠤⠤⠄${RESET}"
}

# Greet and inform the user about the script
function greeter() {
	echo -e "\n${WHITE}Welcome to the ${RED}${NAME}${WHITE} script."
	echo -e "This tool configures your system for red team and CTF workflows."
	echo -e "Includes Docker, Exegol, and optional LLM/note utilities.\n"
	read -p "Press any key to continue..."
}

# Check if the system is supported
function check_system() {
	echo -e "\n${NOTE}${WHITE}Checking if system is supported..."

	if ! grep -iqE 'ubuntu|mint|debian|kali|parrot|peppermint' /etc/os-release && command -v apt &>/dev/null; then
		echo -e "${ERROR}Unsupported OS. This script only supports Debian-based distros."
		exit 1
	else
		echo -e "${GOOD}Supported OS: ${DISTRO:-unknown}"
	fi
}

# Check for internet connection first before proceeding
function check_internet() {
	echo -e "${NOTE}Checking for internet connection..."

	if ping google.com -c 2 &>/dev/null || ping 8.8.8.8 -c 2 &>/dev/null; then
		echo -e "${GOOD}Internet connection is active."
	else
		echo -e "${ERROR}Internet connection is required for the setup."
		exit 1
	fi
}

# Inform again the user
function start() {
	local START_DATE=$(date +"%A, %B %d, %Y %I:%M:%S %p")
	echo -e "\n${NOTE}Hang tight! Setting up your system now: ${START_DATE}\n"
}

# Start by installing all the required dependencies
function install_dependencies() {
local DEPENDENCIES=(git wget curl pipx docker) # Add/edit packages as needed

	echo -e "${NOTE}Updating and upgrading system..."

	apt update -y &>/dev/null
	apt upgrade -y &>/dev/null

	echo -e "${GOOD}System is updated."
	echo -e "${NOTE}Installing dependencies..."


	for DEPENDENCY in "${DEPENDENCIES[@]}"; do
		if [[ "${DEPENDENCY}" == "docker" ]]; then
			if ! command -v docker &>/dev/null; then
				echo -e "${NOTE}Installing Docker from get.docker.com..."

				if (curl -fsSL https://get.docker.com | sh) &>/dev/null; then
					echo -e "${GOOD}Docker installed successfully."
				else
					echo -e "${ERROR}Docker installation failed."
				fi
			else
				echo -e "${GOOD}Docker is already installed."
			fi
		else
			if ! command -v "${DEPENDENCY}" &>/dev/null; then
				echo -e "${NOTE}Installing ${DEPENDENCY}..."

				if apt install -y "${DEPENDENCY}" &>/dev/null; then
					echo -e "${GOOD}${DEPENDENCY} installed successfully."
				else
					echo -e "${ERROR}Failed to install ${DEPENDENCY}."
				fi
			else
				echo -e "${GOOD}${DEPENDENCY} is already installed."
			fi
		fi
	done

	echo -e "${GOOD}Dependencies check complete."
}

# Start and enable Docker service
function start_docker() {
	echo -e "${NOTE}Starting and enabling Docker..."

	systemctl start docker &>/dev/null
	sleep 1
	systemctl enable docker &>/dev/null
	sleep 1

	echo -e "${GOOD}Docker is up and running."
}

# Prepare Exegol wrapper
function install_exegol() {
	local USER=$(logname)
	local USER_HOME=$(eval echo "~${USER}")
	local EXEGOL_PATH="${USER_HOME}/.local/bin/exegol"

	if [[ -f "${EXEGOL_PATH}" ]]; then
		echo -e "${GOOD}Exegol wrapper already exists at ${EXEGOL_PATH}.\n"
	else
		echo -e "${NOTE} ${WHITE}Preparing Python wrapper for Exegol..."

		sudo -u "${USER}" pipx ensurepath &>/dev/null
		sudo -u "${USER}" pipx install exegol &>/dev/null

		echo -e "${NOTE} ${WHITE}Adding Exegol alias..."

		echo "alias exegol='sudo -E ${USER_HOME}/.local/bin/exegol'" >> "${USER_HOME}/.bash_aliases"
		chown "${USER}:${USER}" "${USER_HOME}/.bash_aliases"

		echo -e "${NOTE}Exegol wrapper has been set up.\n"
	fi

	echo -e "You will still need to install the Exegol container image manually."
	echo -e "Recommended command: exegol install free --accept-eula"
	echo -e "Refer to: https://docs.exegol.com/\n"
	read -p "Press any key to continue..."
}

# Install extra utilities useful for red teaming and CTF workflows
function install_extra() {
	local EXTRA_CHOICE

	echo -ne "${NOTE}Do you want to install extra utilities? (y/n): "
	read EXTRA_CHOICE

	EXTRA_CHOICE=$(echo "${EXTRA_CHOICE}" | tr '[:upper:]' '[:lower:]')

	if [[ "${EXTRA_CHOICE}" != "y" && "${EXTRA_CHOICE}" != "yes" ]]; then
		echo -e "${NOTE}Skipping extra utilities installation."
		return
	fi

	if ! command -v flatpak &>/dev/null &>/dev/null; then
		echo -e "${NOTE}Installing Flatpak..."

		if apt install -y flatpak &>/dev/null; then
			echo -e "${GOOD}Flatpak installed successfully."
		else
			echo -e "${ERROR}Failed to install Flatpak."
			return
		fi

	else
		echo -e "${GOOD}Flatpak already installed."
	fi

	echo -e "${NOTE} ${WHITE}Adding Flathub repository..."
	flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

	declare -A PACKAGES=(
		["io.github.bytezz.IPLookup"]="IP Lookup"
		["net.giuspen.cherrytree"]="CherryTree"
	)

	for PACKAGE in "${!PACKAGES[@]}"; do
		if ! flatpak list --app | grep -q "$PACKAGE"; then
			echo -e "${NOTE}Installing ${PACKAGES[$PACKAGE]}..."
			flatpak install -y --noninteractive flathub "$PACKAGE"
		else
			echo -e "${GOOD}${PACKAGES[$PACKAGE]} already installed."
		fi
	done

	echo -e "${NOTE}Installing Ollama..."
	if ! command -v ollama &>/dev/null; then
		if (curl -fsSL https://ollama.com/install.sh | sh) &>/dev/null; then
			echo -e "${GOOD}Ollama installed successfully."
		else
			echo -e "${ERROR}Failed to install Ollama."
		fi
	else
		echo -e "${GOOD}Ollama already installed."
	fi

	if command -v ollama &>/dev/null; then
		if ! ollama list | grep -qi 'deepseek-r1.*1\.5b'; then
			echo -e "${NOTE}Pulling Deepseek R1 - 1.5B model..."
			ollama pull deepseek-r1:1.5b &>/dev/null
		else
			echo -e "${GOOD}Deepseek R1 - 1.5B model already present."
		fi
	else
		echo -e "${NOTE}Ollama not found. Skipping model pull."
	fi
}

# Inform the user that the installation is finished
function end() {
        local END_DATE=$(date +"%A, %B %d, %Y %I:%M:%S %p")
        echo -e "\n${GOOD}Setup completed on: ${END_DATE}\n"
}

# Prompt the user for reboot
function prompt_reboot() {
	local REBOOT_CHOICE
        echo -ne "${NOTE}Would you like to reboot now? (y/n): " 
	read REBOOT_CHOICE

        REBOOT_CHOICE=$(echo "$REBOOT_CHOICE" | tr '[:upper:]' '[:lower:]')

        if [[ "$REBOOT_CHOICE" == "y" || "$REBOOT_CHOICE" == "yes" ]]; then
                echo -e "${NOTE}Rebooting now..."
		sleep 3
                reboot
        else
                echo -e "${NOTE}You can reboot later to apply all changes."
        fi

}

function main() {
	check_sudo
	clear
	banner
	greeter
	check_system
	check_internet
	start
	install_dependencies
	start_docker
	install_exegol
	#install_extra
	end
	prompt_reboot
}
main
