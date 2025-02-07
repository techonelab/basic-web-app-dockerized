#!/bin/bash
echo "preparing workspace..."
sleep 2s

echo "checking required files..." 
sleep 2s

cd $PWD

if grep -q "#change" "tfsource"; then
  echo "please check tfsource and update values"
  exit 1 
else
  source tfsource
  
  echo "initializing variables..."
  sleep 2s

  echo "you may now provision via terraform"
  sleep 2s
fi
sleep 3s
