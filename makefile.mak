now=$(date +"%Y-%m-%d")
./asmFish/fasm.exe "asmFish/asmFishW_base.asm"   -m 262144 "Windows/asmFishW_$now_base.exe"
./asmFish/fasm.exe "asmFish/asmFishW_popcnt.asm" -m 262144 "Windows/asmFishW_$now_popcnt.exe"
./asmFish/fasm.exe "asmFish/asmFishW_bmi2.asm"   -m 262144 "Windows/asmFishW_$now_bmi2.exe"
./asmFish/fasm.exe "asmFish/asmFish_base.asm"   -m 262144 "Linux/asmFish_$now_base"
./asmFish/fasm.exe "asmFish/asmFish_popcnt.asm" -m 262144 "Linux/asmFish_$now_popcnt"
./asmFish/fasm.exe "asmFish/asmFish_bmi2.asm"   -m 262144 "Linux/asmFish_$now_bmi2"