# ad-ctf-infra
Infrastructure and orchestration toolkit for deploying and managing Attack-Defense CTF environments, including challenge containers, core game services, networking, and automated operations.


### How to build and infra
steps :
1. create .env.ctf file where you describe
```
CATEGORIES=intro
TEAMS=4
PLAYER_PER_TEAMS=4
```
Number of team, player per team, and category.
in this repo there is only the intro category but soon i will push also the cryptography, software security, web categories.

2. setup the AWS access keys
```
    set -x AWS_ACCESS_KEY_ID ...
    set -x AWS_SECRET_ACCESS_KEY ... 
    set -x AWS_REGION eu-west-1

```
