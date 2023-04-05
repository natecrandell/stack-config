The only config file of which I'm aware at present is:
	/etc/gitlab/gitlab.rb

There is a service file at:
	/etc/systemd/system/multi-user.target.wants/gitlab-runsvdir.service
but it doesn't appear to be that useful:
	Description=GitLab Runit supervision process

I can see that the install dir is:
	/opt/gitlab