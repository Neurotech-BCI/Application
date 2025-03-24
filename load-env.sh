#!/bin/bash

# Source the .env file to load variables
if [ -f .env ]; then
  source .env
else
  echo "You do not have the projects .env file in this directory"
  exit 1
fi

# return our ip addr env variable
echo "$IP_ADDRESS"