"asmFish\fasm.exe" "asmFish\asmFishW_debug.asm"  -m 262144 "Windows\asmFishW_%DATE:~10,4%-%DATE:~4,2%-%DATE:~7,2%_debug.exe"
"asmFish\fasm.exe" "asmFish\asmFishW_base.asm"   -m 262144 "Windows\asmFishW_%DATE:~10,4%-%DATE:~4,2%-%DATE:~7,2%_base.exe"
"asmFish\fasm.exe" "asmFish\asmFishW_popcnt.asm" -m 262144 "Windows\asmFishW_%DATE:~10,4%-%DATE:~4,2%-%DATE:~7,2%_popcnt.exe"
"asmFish\fasm.exe" "asmFish\asmFishW_bmi2.asm"   -m 262144 "Windows\asmFishW_%DATE:~10,4%-%DATE:~4,2%-%DATE:~7,2%_bmi2.exe"
