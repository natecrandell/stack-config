# Zoneminder Camera Config

Resources

- Reolink docs: `https://reolink.com/wp-content/uploads/2017/01/Reolink-CGI-command-v1.61.pdf`
- Zoneminder/reolink troublehooting thread: `https://forums.zoneminder.com/viewtopic.php?t=25874` (found solutions here)
- Zoneminder/Reolink docs: `https://wiki.zoneminder.com/Reolink` (not that helpful)
- Zoneminder define monitors user guide: `https://zoneminder.readthedocs.io/en/1.32.3/userguide/definemonitor.html`
- Zoneminder docs: (complete, pdf) `https://readthedocs.org/projects/zoneminder/downloads/pdf/stable/`

Best settings I've found

```text
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
  ```

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

## Reolink Camera Information

### Model Comparison

(change this to a table)
RLC-410-5MP		FOV: 80H x 58V		no IR-cut						12V PoE
RLC-520			FOV: 80H x 58V		Auto-switching IR-cut filter	802.3af, 48V Active
RLC-520A		FOV: 80H x 42V		Auto-switching IR-cut filter	802.3af, 48V Active

Firmware: `https://reolink.com/us/download-center/`

Reolink RLC-410-5MP (cam144)

```text
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
```

Reolink RLC-520

```text
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
```
