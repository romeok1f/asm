now := $(shell /bin/date "+%Y-%m-%d")
all:
	./asmFish/fasm "asmFish/asmFishW_base.asm"      -m 50000 "Windows/asmFishW_$(now)_base.exe"
	./asmFish/fasm "asmFish/asmFishW_popcnt.asm"    -m 50000 "Windows/asmFishW_$(now)_popcnt.exe"
	./asmFish/fasm "asmFish/asmFishW_bmi2.asm"      -m 50000 "Windows/asmFishW_$(now)_bmi2.exe"
	./asmFish/fasm "asmFish/pedantFishW_base.asm"   -m 50000 "Windows/pedantFishW_$(now)_base.exe"
	./asmFish/fasm "asmFish/pedantFishW_popcnt.asm" -m 50000 "Windows/pedantFishW_$(now)_popcnt.exe"
	./asmFish/fasm "asmFish/pedantFishW_bmi2.asm"   -m 50000 "Windows/pedantFishW_$(now)_bmi2.exe"
	./asmFish/fasm "asmFish/asmFish_base.asm"      -m 50000 "Linux/asmFish_$(now)_base"
	./asmFish/fasm "asmFish/asmFish_popcnt.asm"    -m 50000 "Linux/asmFish_$(now)_popcnt"
	./asmFish/fasm "asmFish/asmFish_bmi2.asm"      -m 50000 "Linux/asmFish_$(now)_bmi2"
	./asmFish/fasm "asmFish/pedantFish_base.asm"   -m 50000 "Linux/pedantFish_$(now)_base"
	./asmFish/fasm "asmFish/pedantFish_popcnt.asm" -m 50000 "Linux/pedantFish_$(now)_popcnt"
	./asmFish/fasm "asmFish/pedantFish_bmi2.asm"   -m 50000 "Linux/pedantFish_$(now)_bmi2"