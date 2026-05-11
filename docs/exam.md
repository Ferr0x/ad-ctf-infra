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


### DOCKER :

blockonote dockerfile create a flask app by starting from an alpine after it copies the requirements.txt file and install all the requiremets inside the docker instance
in the end after setting /app as workir it runs the command `flash run --host 0.0.0.0`

the dockercompose file setup some basic stuff like max number of pid it expose the port 5000 on the remote port 1337
