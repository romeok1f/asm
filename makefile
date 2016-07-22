now := $(shell /bin/date "+%Y-%m-%d")
all:
	@echo time is $(now)
	./asmFish/fasm "asmFish/asmFishW_base.asm"   -m 262144 "Windows/asmFishW_$(now)_base.exe"
	./asmFish/fasm "asmFish/asmFishW_popcnt.asm" -m 262144 "Windows/asmFishW_$(now)_popcnt.exe"
	./asmFish/fasm "asmFish/asmFishW_bmi2.asm"   -m 262144 "Windows/asmFishW_$(now)_bmi2.exe"
	./asmFish/fasm "asmFish/asmFish_base.asm"   -m 262144 "Linux/asmFish_$(now)_base"
	./asmFish/fasm "asmFish/asmFish_popcnt.asm" -m 262144 "Linux/asmFish_$(now)_popcnt"
	./asmFish/fasm "asmFish/asmFish_bmi2.asm"   -m 262144 "Linux/asmFish_$(now)_bmi2"