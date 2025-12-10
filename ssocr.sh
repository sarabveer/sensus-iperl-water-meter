#!/usr/bin/env bash

set -e

exec ssocr -d 9-11 -C -c decimal /config/www/water_meter_ssocr.png
