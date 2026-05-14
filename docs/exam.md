# NOTES EXAM CLOUD-EDGE-COMPUTING



### GITHUB:
```bash
git clone git@github.com:Ferr0x/ad-ctf-infra.git
git checkout -b develop
git push -u origin develop
touch .gitignore
git add .
git commit -m "chore: init repo structure"
git push
git checkout -b feature/challenge-docker

```
this clone the repo, create the new branch develop, create the file .gitignore and commit this initial structure, and create the feature branch 

```bash
git checkout develop
git merge feature/challenge-docker
git push origin develop
```

so after pushing working code on the feature branch i merged the feature/challenge-docker in the develop. 
 
### DOCKER :

blockonote dockerfile create a flask app by starting from an alpine after it copies the requirements.txt file and install all the requiremets inside the docker instance
in the end after setting /app as workir it runs the command `flash run --host 0.0.0.0`

the dockercompose file setup some basic stuff like max number of pid it expose the port 5000 on the remote port 1337


### TERRAFORM :
So the structure of the dir terraform is this one  :
```bash 
.
├── main.tf
├── modules
│   ├── gameserver
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── security_groups
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── vpc
│   │   ├── main.tf
│   │   └── outputs.tf
│   └── vulnboxes
│       ├── main.tf
│       ├── outputs.tf
│       └── variables.tf
├── outputs.tf
├── templates
│   └── ansible-inventory.tftmpl
├── terraform.tfstate
└── terraform.tfstate.backup

  
```
As we can see there is a main.tf that orchestrate different modules.

1. vpc : first modules that runs and create the network, it expose the ID of vpc the ID of the subnet and the ID of the gateway those ids are passed to main.tf and subsequently to all other modules.
2. gameserver : takes those IDs and create the central server of the game, apply a dedicated security group that only opens SSH and the WireGuard port. the only output is the elastic ip.
3. security group : takes the ids and create a security group and return the security id
4. vulboxes : it is instantiated as many times as files inside ../deploy/vulnboxes that is generated from the file gen.py for each file it creates an istance 


### ANSIBLE

- packer.yml: add my ssh key install wireguard and download and set up docker.
- playbook.yml : there are different plays 
  - gameserver : allow ip forwarding, copy the scripts, copy the wireguard config.
  - vulnboxes : crate password, copy wirguard config,copy the challenges, stars the challenge (file start.sh under challenges) 
  - gameserver pt2: install python and clone forcAD copied it here : (https://github.com/pomo-mondreganto/ForcAD). 

### Makefile
the Makefile it is made to automate the following tasks

1. venv: this is used to create and setup a python virtual environment.
2. prepare: missing file is used to move the challenge inside the right dir and the checker in the right dir, it also merge up all the requirements
3. pack: prepare wireguard packet, create zip with config  
4. infra: create the terraform infrastructure 
5. deploy: execute playbook ansible 
6. all: execute all the task
7. nuke: destroy all the terraform and delete zip file 
