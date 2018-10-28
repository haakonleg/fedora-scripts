#!/bin/bash

regexCPU="Package id 0:  \+([0-9]+)"
regexGPU="Attribute 'GPUCoreTemp' [^)]+): ([0-9]+)"
regexGPUFreq="Attribute 'GPUCurrentClockFreqs' [^)]+): ([0-9]+),([0-9]+)"

cpuTemp=0
cpuMax=0
gpuTemp=0
gpuMax=0
gpuClkFreq=0
gpuClkFreqMax=0
gpuMemFreq=0
gpuMemFreqMax=0

while true
do
    clear

    # Get current CPU temp
    if [[ $(sensors) =~ $regexCPU ]]; then
        cpuTemp=${BASH_REMATCH[1]}
    else
        cpuTemp=0
    fi

    # Check max temp
    if [ $cpuTemp -gt $cpuMax ]; then
        cpuMax=$cpuTemp
    fi

    # Get current GPU temp
    if [[ $(nvidia-settings -q gpucoretemp) =~ $regexGPU ]]; then
	    gpuTemp=${BASH_REMATCH[1]}
    else
	    gpuTemp=0
    fi

    # Check max temp
    if [ $gpuTemp -gt $gpuMax ]; then
        gpuMax=$gpuTemp
    fi

    # Get GPU clock freqs
    if [[ $(nvidia-settings -q gpucurrentclockfreqs) =~ $regexGPUFreq ]]
    then
        gpuClkFreq=${BASH_REMATCH[1]}
        gpuMemFreq=${BASH_REMATCH[2]}
    fi

    # Check max clk/mem freq
    if [ $gpuClkFreq -gt $gpuClkFreqMax ]; then
        gpuClkFreqMax=$gpuClkFreq
    fi
    if [ $gpuMemFreq -gt $gpuMemFreqMax ]; then
        gpuMemFreqMax=$gpuMemFreq
    fi

    printf "\tCurrent\tMax\nCPU\nTemp\t%d\t%d\n\nGPU\nTemp\t%d\t%d\nCore\t%d\t%d\nMem\t%d\t%d" $cpuTemp $cpuMax $gpuTemp $gpuMax $gpuClkFreq $gpuClkFreqMax $gpuMemFreq $gpuMemFreqMax

    sleep 2
done
