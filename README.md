# HooksEasy Localhost CLI at https://hookseasy.com/

<img alt="hookseasy logo" src="https://github.com/TKV-LF/tunnel-client-binaries/blob/main/assets/logo.svg" width="20%" align="right"/>

> This is a CLI tool for https;//hookseasy.com to connect your localhost to HooksEasy server, so that you can *receive your webhooks locally*.

Webhooks testing is a tired job that take a lot of effort to setup. HooksEasy helps you deliver webhooks from anywhere to you localhost with only one command. No account to signup, no server to setup, no hassle.

**Version:** v0.11

## Installation
1. Go to https://hookseasy.com/. A webhook API will be created for you.
2. Copy your webhook API token.
3. Run the following command to install and run the CLI tool. Remember to replace `<YOUR_WEBHOOK_API_TOKEN>` with your webhook API token, and `<YOUR_LOCAL_PORT>` with your local port.
```
curl -sSL https://tkv-lf.github.io/tunnel-client-binaries/install.sh | bash -s -- --t <YOUR_WEBHOOK_API_TOKEN> --h http://localhost:<YOUR_LOCAL_PORT>
```

## License
This project is licensed under the MIT license, see `LICENSE.txt`.