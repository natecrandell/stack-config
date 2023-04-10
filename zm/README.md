# Zoneminder Build Notes

## References

- Ubuntu basic install: https://zoneminder.readthedocs.io/en/latest/installationguide/ubuntu.html
- Multi-server install: https://zoneminder.readthedocs.io/en/latest/installationguide/multiserver.html
- Zoneminder API Docs: https://zoneminder.readthedocs.io/en/latest/api.html
- Zoneminder Release Notes: https://github.com/ZoneMinder/zoneminder/releases

# Notes:
- Go through and build zm-1 first. Then do the exact same process for additional servers, skipping only the database steps.
- 10.1.2.0/24 is used as mgmt network. It has an internet gateway for updates, and the proxy hits the zm nodes on this subnet.
- 10.1.3.0/24 is the camera network. It is unmanaged, has no gateway, and is isolated from all other networks.
- 10.1.1.0/24 is temporarily used on zm-2 until I get rid of the D-Link DCS-932L cameras
- The zm nodes mount to a cephfs share using the pve host's connection. This is intended to be used for video recordings.
- The local events storage is /mnt/libraries/zoneminder/events

## Container Config

```text
arch: amd64
cores: 4
hostname: zm-1
memory: 2048
mp0: /mnt/pve/cephfs/libraries/,mp=/mnt/libraries
net0: name=eth2,bridge=vmbr2,firewall=1,gw=10.1.2.1,hwaddr=0A:63:3D:38:B5:06,ip=10.1.2.221/24,ip6=auto,type=veth
net1: name=eth3,bridge=vmbr3,hwaddr=02:B4:5B:B0:D1:82,ip=10.1.3.221/24,ip6=auto,type=veth
onboot: 1
ostype: ubuntu
rootfs: local:221/vm-221-disk-0.raw,size=6G
startup: order=3
swap: 0
```

## Standard System Config

Perform the [standard system config](../shared/standard-config.md).

## Zoneminder Config

`https://zoneminder.readthedocs.io/en/latest/installationguide/ubuntu.html#ubuntu-22-04-jammy`

```bash
apt install -y software-properties-common
add-apt-repository ppa:iconnor/zoneminder-1.36 && apt update && apt install -y zoneminder
a2enmod rewrite; a2enconf zoneminder; systemctl restart apache2

vim /etc/php/8.1/apache2/php.ini
# Uncomment and change date.timezone to your tz. http://php.net/manual/en/timezones.php
date.timezone = America/Denver
```

## MySQL Config (zm-1 only)

```bash
rm /etc/mysql/my.cnf  #(this removes the current symbolic link)
cp /etc/mysql/mysql.conf.d/mysqld.cnf /etc/mysql/my.cnf
vim /etc/mysql/my.cnf
bind-address            = 127.0.0.1,10.1.2.221
systemctl restart mysql

# Setup user/privs for multi-server (perform on zm-1 only)
# repeat this process for all additional servers
mysql -uroot -p
CREATE USER 'zmuser'@'10.1.2.222' IDENTIFIED BY 'zmpass';
GRANT ALL ON zm.* to 'zmuser'@'10.1.2.222';
flush privileges;
\q
```

# Event Storage Config

Ensure /mnt/libraries is mounted.

```bash
mkdir -p /mnt/libraries/events
chown -R www-data:crandell /mnt/libraries/zoneminder/
```

## Misc Config

Leave all config files in /etc/zm/ and /etc/zm/conf.d/ as they are. Adding /etc/zm/conf.d/zm-*.conf will override defaults.

```bash
# The following step will have a corresponding file for zm-*
ln -s /mnt/libraries/config/stack/zm/zm-1.conf /etc/zm/conf.d/zm-1.conf

ln -s /mnt/libraries/config/stack/shared/clean-cache.cron /etc/cron.d/clean-cache

systemctl enable --now zoneminder
```

## Cleanup

Remove mysql for nodes that aren't zm-1

```bash
apt remove mysql-server*
apt autoremove
```

## Zoneminder Camera Config

Camera config resources:
	Reolink docs: https://reolink.com/wp-content/uploads/2017/01/Reolink-CGI-command-v1.61.pdf
	Zoneminder/reolink troublehooting thread: https://forums.zoneminder.com/viewtopic.php?t=25874 (found solutions here)
	Zoneminder/Reolink docs: https://wiki.zoneminder.com/Reolink (not that helpful)
	Zoneminder define monitors user guide: https://zoneminder.readthedocs.io/en/1.32.3/userguide/definemonitor.html
	Zoneminder docs: (complete, pdf) https://readthedocs.org/projects/zoneminder/downloads/pdf/stable/

Best settings I've found

	All cams:
		Timestamp Label Format: %N %m/%d/%y %H:%M:%S
		Image Buffer Size (frames): 3

	D-Link DCS-932L
		Source Type: Remote
		Protocol: HTTP
		Method: Regexp
		Host Name: [user]:[pwd]@[ip]
		Port: 80
		Path: /video.cgi

	Reolink RLC-410-5MP (bullet) & RLC-520 (dome)
		Source Type: Ffmpeg
		Source Path: rtmp://[ip]/bcs/channel0_sub.bcs?channel=0&stream=1&user=[user]&password=[pwd]
		Method: TCP
		Options: buffer_size=128000
		DecoderHWAccelName: vaapi
		Target colorspace: 32 bit color
		Capture Resolution: (match camera settings for fluent stream)

## Reolink Notes

RTMP

  This work best, as noted above. Other available streams:

  ```text
  clear/main/stream0 - rtmp://[ip]/bcs/channel0_main.bcs?channel=0&stream=0&user=[user]&password=[pwd]
  fluent/sub/stream1 - rtmp://[ip]/bcs/channel0_sub.bcs?channel=0&stream=1&user=[user]&password=[pwd]
  ext/blend/stream2  - rtmp://[ip]/bcs/channel0_ext.bcs?channel=0&stream=2&user=[user]&password=[pwd]
  ```

RTSP

  For some cameras this resulted in smearing, connectivity struggles, and general unreliability.

  ```text
  Source Type: Ffmpeg
  Source Path: rtsp://[user]:[pwd]@[ip]/h264Preview_01_sub
  Method: TCP
  Options: reorder_queue_size=300,allowed_media_types=video
  ```

Remote RTP

  For some cameras this resulted in connectivity struggles, logging complaints, and general unreliability.

  ```text
  Source Type: Remote
  Protocol: RTSP
  Method: RTP/Unicast
  Host Name: [user]:[pwd]@[ip]
  Port: 554
  Path: /h264Preview_01_sub
  ```

Note: I've been able to use ffmpeg to record directly from a Reolink cam, with audio:

```bash
# hi res (clear stream): 
ffmpeg -i "rtmp://10.1.3.150/bcs/channel0_main.bcs?channel=0&stream=0&user=admin&password=[pwd]" /mnt/libraries/videos/cam150-test.mp4
# low res (fluent stream):
ffmpeg -i "rtmp://10.1.3.150/bcs/channel0_sub.bcs?channel=0&stream=1&user=admin&password=[pwd]" /mnt/libraries/videos/cam150-test2.mp4
```

# Reolink Camera information
	

	Reolink RLC-410-5MP (cam144)
		network->advanced->advanced
			media: 9000
			http: 80
			https: 443
			rtsp: 554
			rtmp: 1935
			onvif: 8000
		recording->encode
			clear stream
				record audio: false
				resolution: 2560*1920
				frame rate: 30fps
				max bitrate: 6144kbps
				h.264 profile: high (other options: base, main)
			fluent stream
				resolution: 640x480
				frame rate: 15fps
				max bitrate: 384kbps
				h.264 profile: main
		system->information
			model: rlc-410-5mp
			build no: build 20031401
			hardware no: IPC_51516M5M
			config version: v2.0.0.0
			firmware version: v2.0.0.647_20031401
			details: IPC_51516M5M110000000100000
			client version: v1.0.261

	Reolink RLC-520
		camera->stream
			clear
				resolution: 2560*1920
				frame rate: 30fps
				max bitrate: 6144kbps
			fluent stream
				resolution: 640x480
				frame rate: 15fps
				max bitrate: 384kbps
		camera->info
			Model: RLC-520
			UID: 952700037CLM1X25
			Build No: build 20121112
			Hardware No: IPC_515B16M5M
			Config Version: v3.0.0.0
			Firmware Version: v3.0.0.136_20121112
			Details: IPC_515B16M5MS10E1W01100000001
