#!/usr/bin/env bash
#11
source /etc/network_turbo
aria2c -c -x 16 -s 16 -k 1M -d /root -o start-sd.sh https://github.com/gluttony-10/1/blob/main/start-sd.sh
cd /root/stable-diffusion-webui/ && python launch.py --port 6006 --api --no-download-sd-model --xformers --enable-insecure-extension-access --controlnet-dir /root/autodl-fs/models/ControlNet --ckpt-dir /root/autodl-tmp/models/Stable-diffusion --embeddings-dir /root/autodl-tmp/models/embeddings --lora-dir /root/autodl-tmp/models/lora --vae-dir /root/autodl-tmp/models/vae --lyco-dir /root/autodl-tmp/models/lycoris
