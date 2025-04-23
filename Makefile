# Makefile for Flutter project

.PHONY: build

build:
	dart run build_runner build

build-icon:
	flutter pub run flutter_launcher_icons:main