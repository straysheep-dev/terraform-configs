#!/bin/bash

# Generates an inventory.ini file for use with ansible from deployed resources

group_name='[remotegroup]'
echo "$group_name" | tee inventory.ini; terraform show | grep -P '\bipv4_address\b' | awk -F'"' '{print $2":22 ansible_user=root"}' | tee -a inventory.ini