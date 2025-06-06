#!/usr/bin/env bash

## nezha
DASH_VERSION="$(curl -s https://api.github.com/repos/nezhahq/nezha/releases | grep -m 1 -oP '"tag_name":\s*"\K[^"]+')"

mkdir -p /app/nezha/ && cd /app/nezha
wget -q https://github.com/nezhahq/nezha/releases/download/${DASH_VERSION}/dashboard-linux-amd64.zip
unzip dashboard-linux-amd64.zip && chmod +x dashboard-linux-amd64 && rm dashboard-linux-amd64.zip

## nezha-agent
AGENT_VERSION="$(curl -s https://api.github.com/repos/nezhahq/agent/releases | grep -m 1 -oP '"tag_name":\s*"\K[^"]+')"

mkdir -p /app/nezha-agent && cd /app/nezha-agent
wget -q https://github.com/nezhahq/agent/releases/download/${AGENT_VERSION}/nezha-agent_linux_amd64.zip
unzip nezha-agent_linux_amd64.zip && chmod +x nezha-agent && rm nezha-agent_linux_amd64.zip


