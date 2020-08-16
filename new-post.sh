#!/bin/bash
filename="src/content/post/$(date '+%Y-%m-%d')-$(echo $@ | tr ' ' '-' | tr A-Z a-z | sed "s/[^a-z\\-]//g").md"

[ "$*" = "" ] && echo "u forgot title my d00d" && exit 1

cat > $filename <<EOF
+++
author = "Ryan Heywood"
title = "$*"
date = "$(date '+%Y-%m-%d %H:%M:%S %z')"
description = ""
tags = []
featured = false
+++


EOF

${EDITOR:-vim} "$filename" +'normal G'
