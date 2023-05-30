# Installing on Debian Based Distributions

Debian 11 (“bullseye”) and Ubuntu 22.04 LTS (“Jammy Jellyfish”) are only supported with OTP releases. For installing OTP releases on these distributions, please follow [this guide](./otp_en.md).

Debian 12 (“bookworm”), Ubuntu 23.04 (“Lunar Lobster”) and later are supported with both OTP releases and from-source installations. For a from-source installation on Debian 12 and later, please follow [this guide](./debian_bookworm_en.md).

OTP releases are as close as you can get to binary releases with Erlang/Elixir. The release is self-contained, and provides everything needed to boot it, it is easily administered via the provided shell script to open up a remote console, start/stop/restart the release, start in the background, send remote commands, and more.

From-source installation is not supported for distributions before Debian 12 and Ubuntu 23.04, as they do not ship with Elixir 1.14+, required by Akkoma and its dependencies. 
Debian 11 only officially provides Elixir 1.10 (released January 2020), and Ubuntu 22.04 LTS only officially provides Elixir 1.12 (released May 2021).
Well-known and trusted third-party repositories, like the [Erlang Solutions](https://www.erlang-solutions.com/downloads/) repository, do not currently provide Elixir 1.14+ either.

If you are migrating a from-source installation, please follow [this guide](./migrating_from_source_otp_en.md) to migrate to an OTP installation.

#### Further reading

{! installation/further_reading.include !}

{! support.include !}
