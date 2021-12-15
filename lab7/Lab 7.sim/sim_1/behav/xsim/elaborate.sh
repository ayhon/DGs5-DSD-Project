#!/bin/bash -f
# ****************************************************************************
# Vivado (TM) v2020.2 (64-bit)
#
# Filename    : elaborate.sh
# Simulator   : Xilinx Vivado Simulator
# Description : Script for elaborating the compiled design
#
# Generated by Vivado on Mon Dec 13 18:11:06 CET 2021
# SW Build 3064766 on Wed Nov 18 09:12:47 MST 2020
#
# Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
#
# usage: elaborate.sh
#
# ****************************************************************************
set -Eeuo pipefail
# elaborate design
echo "xelab -wto e04462ccd2e84e33bb74d5532efe4017 --incr --debug typical --relax --mt 8 -L xil_defaultlib -L secureip --snapshot pong_fsm_tb_behav xil_defaultlib.pong_fsm_tb -log elaborate.log"
xelab -wto e04462ccd2e84e33bb74d5532efe4017 --incr --debug typical --relax --mt 8 -L xil_defaultlib -L secureip --snapshot pong_fsm_tb_behav xil_defaultlib.pong_fsm_tb -log elaborate.log

