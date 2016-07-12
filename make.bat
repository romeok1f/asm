"asmFish\fasm.exe" "asmFish\asmFishW_base.asm"   -m 262144 "Windows\asmFishW_%DATE:~10,4%-%DATE:~4,2%-%DATE:~7,2%_base.exe"
"asmFish\fasm.exe" "asmFish\asmFishW_popcnt.asm" -m 262144 "Windows\asmFishW_%DATE:~10,4%-%DATE:~4,2%-%DATE:~7,2%_popcnt.exe"
"asmFish\fasm.exe" "asmFish\asmFishW_bmi2.asm"   -m 262144 "Windows\asmFishW_%DATE:~10,4%-%DATE:~4,2%-%DATE:~7,2%_bmi2.exe"
"asmFish\fasm.exe" "asmFish\asmFish_base.asm"   -m 262144 "Linux\asmFish_%DATE:~10,4%-%DATE:~4,2%-%DATE:~7,2%_base"
"asmFish\fasm.exe" "asmFish\asmFish_popcnt.asm" -m 262144 "Linux\asmFish_%DATE:~10,4%-%DATE:~4,2%-%DATE:~7,2%_popcnt"
"asmFish\fasm.exe" "asmFish\asmFish_bmi2.asm"   -m 262144 "Linux\asmFish_%DATE:~10,4%-%DATE:~4,2%-%DATE:~7,2%_bmi2"

