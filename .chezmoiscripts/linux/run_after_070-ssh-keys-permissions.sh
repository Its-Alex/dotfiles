#!/bin/bash

# Secretless applies deploy no keys: only touch what is there.
for key in itsalex itsalex-old relex; do
    if [ -f "$HOME/.ssh/$key" ]; then
        chmod 600 "$HOME/.ssh/$key"
    fi
    if [ -f "$HOME/.ssh/$key.pub" ]; then
        chmod 644 "$HOME/.ssh/$key.pub"
    fi
done
