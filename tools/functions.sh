#!/usr/bin/env bash

function mullvad_create_chain() {
	sudo sed "s/^Endpoint.*/Endpoint = $2:$3/" "/etc/wireguard/mullvad-$4.conf" \
		| sudo tee "/etc/wireguard/wireguard-$3$1.conf"

	echo -e "\n\nAdded wireguard-$4$1.conf"
}

function mullvad_switch_chain() {
	sudo systemctl disable "wg-quick@$1"
	sudo systemctl enable "wg-quick@$2"

	echo "Rebooting in 5 seconds..."; sleep 5 && sudo reboot
}
