#!/usr/bin/env bash
source /etc/network_turbo
cd /root/stable-diffusion-webui/ && ./webui.sh -f --port 6006 --api --no-download-sd-model --xformers --enable-insecure-extension-access --controlnet-dir /root/autodl-fs/models/ControlNet
