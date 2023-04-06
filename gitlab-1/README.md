# Gitlab Build Notes

Ubuntu 16.04 CT
`https://about.gitlab.com/installation/#ubuntu`

## File Locations

- /opt/gitlab #install dir
- /etc/gitlab/gitlab.rb #config
- /etc/systemd/system/multi-user.target.wants/gitlab-runsvdir.service

### Dependencies

```bash
apt-get install curl openssh-server ca-certificates postfix -y
curl -sS https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh | sudo bash
apt-get install gitlab-ce
dpkg -i gitlab-ce-XXX.deb
gitlab-ctl reconfigure
```

Go to web address, default uname is root

Do this:

- Disable public sign ups
- While logged in to the web client:
-- wrench icon -> gear icon -> settings -> Sign-up Restrictions section -> uncheck 'Sign-up enabled'

### Configure SMTP

`https://docs.gitlab.com/omnibus/settings/smtp.html`

```bash
mv /etc/gitlab/gitlab.rb /etc/gitlab/gitlab.rb.bak
vim /etc/gitlab/gitlab.rb
external_url 'http://git.crandell.us' #Use http so Gitlab CT listens on 80
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp.gmail.com"
gitlab_rails['smtp_port'] = 587
gitlab_rails['smtp_user_name'] = "nate@crandell.us"
gitlab_rails['smtp_password'] = "smtp password"
gitlab_rails['smtp_domain'] = "smtp.gmail.com"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['smtp_tls'] = false
gitlab_rails['smtp_openssl_verify_mode'] = 'peer'

gitlab-ctl reconfigure
```

### Create first repo

I'll create a 'saltconf' repo

On salt.snaptek.us

```bash
git config --global user.name "Nate"
git config --global user.email "nate@snaptek.us"
cd /srv
git init
git remote add origin git@git.snaptek.us:nate/saltconf.git
git add .
git commit -m "Initial commit"
git push -u origin master
```

### Troubleshooting Notes

- 2017-08-10 The above command requests a password for git@git.snaptek.us. SOLUTION - make sure that on the remote box, in this case salt.snaptek.us, both users root & nate can successfully do `ssh -vT git@git.snaptek.us`. (This requires that ~/.ssh contains the public and private keys)
- Had another problem when I tried to push from dns.snaptek.us to a repo. SSH wouldn't work because of some PTY thing. Solution was to use the IP address instead of DNS for the repo. This should only be an issue on dns.snaptek.us.

2017-08-10 Here's the cli notes from when I created the letsencrypt repo

```bash
git config --global user.name "Nate"
git config --global user.email "nate@snaptek.us"
```

Create a new repository

```bash
git clone git@git.snaptek.us:nate/letsencrypt.git
cd letsencrypt
touch README.md
git add README.md
git commit -m "add README"
git push -u origin master
```

Existing folder

```bash
cd existing_folder
git init
git remote add origin git@git.snaptek.us:nate/letsencrypt.git
git add .
git commit -m "Initial commit"
git push -u origin master
```

Existing Git repository

```bash
cd existing_repo
git remote add origin git@git.snaptek.us:nate/letsencrypt.git
git push -u origin --all
git push -u origin --tags
```

## Configure Remote User

- Create a new key pair
-- `ssh-keygen -t ed25519 -C "nate@crandell.us"`
- Create config file
-- `vim ~/.ssh/config`
--- Host git.crandell.us
---     Hostname gitlab-1.crandell.us
---     User git
---     IdentityFile /root/.ssh/id_ed25519
- Add public SSH key to project

## I always have a hard time finding Deploy Keys

click git-lab icon in upper left -> click on project -> settings icon (left, JUST HOVER) -> REPOSITORY -> Deploy Keys

## Gitlab Container Registry

I followed [this guide](https://juju.is/tutorials/using-gitlab-as-a-container-registry) to figure out how to use my Gitlab as a container registry for Docker and/or Kubernetes.

```bash
docker login gitlab.crandell.us:5050 -u nate
docker build -t gitlab.crandell.us:5050/infr/ctr:latest .
docker push gitlab.crandell.us:5050/infr/ctr
```
