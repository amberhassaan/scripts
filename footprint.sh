#!/bin/bash

MEM_PCNT=4
RSS=6
NAME=11

ps aux | awk "{ if (\$$NAME ~ /$1/) { print \$0 }}" | \
  awk "{ mem+=\$$MEM_PCNT; rss+=\$$RSS; } END{ printf \"$1 memory usage=%g%%, rss=%gMB\\n\", mem, rss/1024 }"
