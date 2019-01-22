# Squid Proxy

Containerized Squid 3 proxy on Ubuntu 16.04

## Usage

Place configurations in `configs/` and then use them with

	./squid.sh stop
	./squid.sh config configs/my_config.conf # for example
	./squid.sh run

## Configuration

This project ships with a slightly modified config derived from the default configuration.

Search for `CUSTOM` and see the acl entries there ; some of the default values are turned off for a more relaxed browsing, and some example lines are added.

## Testing

Try to access using the test module (curl, wget or busybox required) from machine on an allowed subnet ; clone this repo to there.

Example command:

	./squid.sh test http://example.com | less
