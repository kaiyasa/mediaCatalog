#!/bin/bash

show() {
    find "$1" -follow -type f -exec du -kL '{}' \; | sort -f -k2 | egrep -v '\.par2$|\.ver$'
}

show "$1"
