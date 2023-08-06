# kusanali

<p><img width="256" height="341" src="https://github.com/iii-v/kusanali/assets/142994237/537e04a5-1ca2-4a55-9eaa-9609a4ec1921"></p>

_kusanali_ is an uncompromising Stable Diffusion bootstrapper. By using it, you agree to cede control over minutiae of installation and configuration. In return, _kusanali_ gives you speed, determinism, and freedom from wrangling with Python virtualenv setup, missing library imports, and ensuring any Stable Diffusion installation does not interfere with your pre-existing Python projects. You will save time and mental energy for more important matters.

_kusanali_ does not make any assumptions on the state of your machine and what's installed on it, so long as the prerequisties below are met.

Try it out now using the instructions below.

## Features

**Why should you use this over the standard installation/startup methods ?**

- Proper Python version and environment isolation with [pyenv](https://github.com/pyenv/pyenv).
- No unwanted interactions or side effects with any pre-exisiting Python libraries, and entrypoints pointing to different Python versions.
- Auto-installation & updates of popular Stable Diffusion workflow tools on every startup:
  - [ControlNet](https://github.com/Mikubill/sd-webui-controlnet)
  - [Regional Prompter](https://github.com/hako-mikan/sd-webui-regional-prompter)

## Prerequisites

- **You need to be on Windows 10/11 with an Nvidia GPU.**
- GPUs from other manufacturers have yet to be tested and there are no guarantees they will work.

## Installation

1. Open PowerShell.
2. Run the following command to create desktop shortcuts for Automatic1111 and ComfyUI:
   ```ps1
   iex (iwr "https://raw.githubusercontent.com/iii-v/noise/main/scripts/Save-Scripts.ps1").Content
   ```

## Usage

1. Click on the desktop shortcuts to launch that specific interface.
   - This may take some time on your first run.
   - You can have multiple interfaces running simultaneously, but not multiple instances of the same interface.
2. To terminate, simply close the console window.

## Notes

- Automatic1111 is installed at `$HOME\stable-diffusion\automatic1111`.
- Model files are to be added to `$HOME\stable-diffusion\models`, if any.
- Tested on Windows 10 22H2 with an Nvidia GeForce GTX 1070.
