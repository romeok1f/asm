set year=%date:~10,4%
set month=%date:~4,2%
set day=%date:~7,2%
set filename=%year%_%month%_%day%

echo %DATE:~10,4%%DATE:~4,2%%DATE:~7,2%
"asmFish\fasm.exe" "asmFish\asmFishW_base.asm"   -m 262144 "Windows\asmFishW_%DATE:~10,4%-%DATE:~4,2%-%DATE:~7,2%_base.exe"
"asmFish\fasm.exe" "asmFish\asmFishW_popcnt.asm" -m 262144 "Windows\asmFishW_%DATE:~10,4%-%DATE:~4,2%-%DATE:~7,2%_popcnt.exe"
"asmFish\fasm.exe" "asmFish\asmFishW_bmi2.asm"   -m 262144 "Windows\asmFishW_%DATE:~10,4%-%DATE:~4,2%-%DATE:~7,2%_bmi2.exe"
