#!/usr/bin/env bash
wget -q -O /root/start.sh https://github.com/gluttony-10/1/blob/main/start-autodl.sh
source /etc/network_turbo
cd /root/stable-diffusion-webui/ && ./webui.sh -f --port 6006 --api --no-download-sd-model --xformers --enable-insecure-extension-access --controlnet-dir /root/autodl-fs/models/ControlNet --ckpt-dir /root/autodl-tmp/models/Stable-diffusion --embeddings-dir /root/autodl-tmp/models/embeddings --lora-dir /root/autodl-tmp/models/lora --vae-dir /root/autodl-tmp/models/vae --lyco-dir /root/autodl-tmp/models/lycoris
