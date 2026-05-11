import argparse
import datetime
import base64
import os
import shutil
import zipfile

import wgconfig
import wgconfig.wgexec as wgexec
import yaml

ROUTER_ADDR = '10.254.0.1/8'
SERVER_IP = "172.241.241.241"

def gen_forcad_config(teams: int, start_time, output="deploy/config.yml", default_score=2500, gamemode="classic", round_time=60, timezone="Europe/Rome", flag_lifetime=5, game_hardness=10.0):
    teams = yaml.dump({"teams": [{"ip": f"10.60.{team_id}.1", "name": f"Team #{team_id}"} for team_id in range(teams + 1)]})
    standard_conf = f"""
game:
  mode: classic
  round_time: {round_time}
  start_time: {start_time:%Y-%m-%d %H:%M:%S}
  timezone: {timezone}

  default_score: {default_score}
  flag_lifetime: {flag_lifetime}
  game_hardness: {game_hardness}
  inflation: true

tasks:
  - checker: test_service/checker.py
    checker_timeout: 10
    checker_type: hackerdom
    gets: 2
    name: test_basic_service
    places: 5
    puts: 2

{teams}
"""
    with open(output, 'w') as f:
        f.write(standard_conf)

def gen_iptables(teams: int, output="deploy/bin"):
    common_commands = """#!/bin/bash
iptables-save | grep -v AD_CTF_SETUP | iptables-restore

iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
iptables -P FORWARD DROP

# TTL reset
iptables -t mangle -A POSTROUTING -o wg0 -j TTL --ttl-set 64 -m comment --comment "AD_CTF_SETUP"

# NAT everything
iptables -t nat -A POSTROUTING -o wg0 -j MASQUERADE -m comment --comment "AD_CTF_SETUP"

# ??
iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT -m comment --comment "AD_CTF_SETUP"

# Team players can connect to each others
"""

    for team_id in range(teams + 1):
        common_commands += """
iptables -A FORWARD -s 10.60.{team_id}.0/24 -d 10.60.{team_id}.0/24 -j ACCEPT -m comment --comment "AD_CTF_SETUP"
""".format(team_id=team_id)

    open_commands = common_commands + """
### OPEN
# Any player can connect to any vulnbox
iptables -A FORWARD -s 10.80.0.0/16 -d 10.60.0.0/16 -j ACCEPT -m comment --comment "AD_CTF_SETUP"

# Any vulnbox can connect to any vulnbox
iptables -A FORWARD -s 10.60.0.0/16 -d 10.60.0.0/16 -j ACCEPT -m comment --comment "AD_CTF_SETUP"
"""

    os.makedirs(output, exist_ok=True)
    with open(os.path.join(output, 'net_open.sh'), 'w') as f:
        f.write(open_commands)

    closed_commands = common_commands + """
### CLOSED
# Teams can connect to their vulnbox
"""

    for team_id in range(teams + 1):
        closed_commands += """
iptables -A FORWARD -s 10.80.{team_id}.0/24 -d 10.60.{team_id}.1/32 -j ACCEPT -m comment --comment "AD_CTF_SETUP"
""".format(team_id=team_id)

    with open(os.path.join(output, 'net_closed.sh'), 'w') as f:
        f.write(closed_commands)


def gen_wg_profile(server_ip: str, server_pub: str, priv: str, addr: str):
    wc = wgconfig.WGConfig('/tmp.conf')
    wc.initialize_file()
    wc.add_attr(None, 'PrivateKey', priv)
    wc.add_attr(None, 'Address', addr)
    wc.add_peer(server_pub)
    wc.add_attr(server_pub, 'Endpoint', f'{server_ip}:5182')
    wc.add_attr(server_pub, 'AllowedIPs', '10.0.0.0/8')
    wc.add_attr(server_pub, 'PersistentKeepalive', '25')
    return '\n'.join(wc.lines)


def gen_wireguard(server_ip: str, server_priv: str, server_pub: str, teams: int, players_per_team: int, output: str="deploy/"):
    wg_peers = []

    tms = os.path.join(output, "teams/")
    os.makedirs(tms)
    vbx = os.path.join(output, "vulnboxes/", "wg")
    os.makedirs(vbx)
    router = os.path.join(output, "router/")
    os.makedirs(router)

    for team_id in range(teams + 1):
        vulnbox_priv, vulnbox_pub = wgexec.generate_keypair()
        wg_peers.append({
            'keys': {'public': vulnbox_pub},
            'allowed-ips': [f'10.60.{team_id}.1/32']
        })

        with open(os.path.join(vbx, f'team{team_id}'), 'w') as f:
            f.write(gen_wg_profile(server_ip, server_pub, vulnbox_priv, f'10.60.{team_id}.1'))

        if team_id == 0:
            continue

        team = os.path.join(tms, f"team{team_id}")
        os.mkdir(team)

        for player_id in range(1, players_per_team + 1):
            player_priv, player_pub = wgexec.generate_keypair()
            wg_peers.append({
                'keys': {'public': player_pub},
                'allowed-ips': [f'10.80.{team_id}.{player_id}/32']
            })

            with open(os.path.join(team, f"player{player_id}.conf"), 'w') as f:
                f.write(gen_wg_profile("@@CHANGEME@@", server_pub, player_priv, f"10.80.{team_id}.{player_id}"))

    netplan_config = {
        'version': 2,
        'renderer': 'networkd',
        'tunnels': {
            'wg0': {
                'mode': 'wireguard',
                'key': server_priv,
                'port': 5182,
                'addresses': [ROUTER_ADDR],
                'peers': wg_peers,
            }
        },
    }

    with open(os.path.join(router, 'router.yaml'), 'w') as f:
        f.write(yaml.dump({'network': netplan_config}))

def main():
    args = argparse.ArgumentParser()
    args.add_argument('--teams', type=int, required=True)
    args.add_argument('--players-per-team', type=int, required=True)
    args = args.parse_args()

    server_priv, server_pub = wgexec.generate_keypair()
    print('[WG] Server private key:', server_priv)
    print('[WG] Server public key:', server_pub)

    # Delete the deploy folder.
    shutil.rmtree('deploy', ignore_errors=True)

    gen_wireguard(SERVER_IP, server_priv, server_pub, args.teams, args.players_per_team)
    gen_iptables(args.teams)
    gen_forcad_config(args.teams, datetime.datetime.now())

if __name__ == '__main__':
    main()

