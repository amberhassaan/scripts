#!/bin/bash

column -s, -t -n "$@" | view -c 'set nowrap' -
