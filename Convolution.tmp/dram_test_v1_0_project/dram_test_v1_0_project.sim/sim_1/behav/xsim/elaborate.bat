@echo off
REM ****************************************************************************
REM Vivado (TM) v2021.1 (64-bit)
REM
REM Filename    : elaborate.bat
REM Simulator   : Xilinx Vivado Simulator
REM Description : Script for elaborating the compiled design
REM
REM Generated by Vivado on Tue Nov 28 19:15:23 -0500 2023
REM SW Build 3247384 on Thu Jun 10 19:36:33 MDT 2021
REM
REM IP Build 3246043 on Fri Jun 11 00:30:35 MDT 2021
REM
REM usage: elaborate.bat
REM
REM ****************************************************************************
REM elaborate design
echo "xelab -wto fc37cf8b47bd43959c63bc452b8d175c --incr --debug typical --relax --mt 2 -L xil_defaultlib -L fifo_generator_v13_2_5 -L unisims_ver -L unimacro_ver -L secureip -L xpm --snapshot wrapper_tb_behav xil_defaultlib.wrapper_tb xil_defaultlib.glbl -log elaborate.log"
call xelab  -wto fc37cf8b47bd43959c63bc452b8d175c --incr --debug typical --relax --mt 2 -L xil_defaultlib -L fifo_generator_v13_2_5 -L unisims_ver -L unimacro_ver -L secureip -L xpm --snapshot wrapper_tb_behav xil_defaultlib.wrapper_tb xil_defaultlib.glbl -log elaborate.log
if "%errorlevel%"=="0" goto SUCCESS
if "%errorlevel%"=="1" goto END
:END
exit 1
:SUCCESS
exit 0
