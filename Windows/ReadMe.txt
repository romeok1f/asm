If you observe a crash in asmFish, please raise an issue here and give me the following information:
  - name of the executable that crashed
  - exception code and exception offset
  - a log of the commands that were sent to asmFish by your gui before the crash
Simply stating that asmFish crashed in your gui is useless information by itself.
asmFish is known to have problems in the fritz15 gui, while it plays much better in the fritz11 gui.
Any help with this issue would be appreciated.



the NumeTest.exe should display the identified cores of your computer
simply run this console program and and give it the commands:
setoption name threads value XX
go depth 25

example output on a quadcore:
 *** General Verbosity ON !! ***

*** enumerating nodes ***
node number = 0: group = 0, mask = 0x000000000000000F
*** finished enumerating nodes ***

*** enumerating processor cores ***
 group = 0, mask = 0x0000000000000001, belongs to node 0
 group = 0, mask = 0x0000000000000002, belongs to node 0
 group = 0, mask = 0x0000000000000004, belongs to node 0
 group = 0, mask = 0x0000000000000008, belongs to node 0
*** finished enumerating processor cores ***

*** matching cores to nodes ***
node number = 0: group = 0, mask = 0x000000000000000F, cores in node = 4, cmh ta
ble = 0x0000000001560000
 total processor cores found: 4
*** finished matching cores to nodes ***

Thread_IdleLoop enter
response time:  97754 us
response time:  103070 us
setoption name threads value 4
Thread_IdleLoop enter
Thread_IdleLoop enter
Thread_IdleLoop enter
response time:  1993 us
response time:  0 us
go depth 25
response time:  51 us
MainThread_Think
Thread_Think
Thread_Think
Thread_Think
Thread_Think
response time:  0 us
info depth 1 multipv 1 time 1 nps 20000 score cp 75 nodes 20 tbhits 0 pv e2e4
info depth 2 multipv 1 time 1 nps 366000 score cp 97 nodes 366 tbhits 0 pv d2d4
d7d6
info depth 3 multipv 1 time 1 nps 1660000 score cp 17 nodes 1660 tbhits 0 pv d2d
4 d7d5 c2c3
info depth 4 multipv 1 time 2 nps 1501000 score cp 29 nodes 3002 tbhits 0 pv d2d
4 g8f6 b1c3 d7d5
info depth 5 multipv 1 time 2 nps 2126000 score cp 4 upperbound nodes 4252 tbhit
s 0 pv d2d4 d7d5
info depth 5 multipv 1 time 3 nps 2190666 score cp 0 nodes 6572 tbhits 0 pv d2d4
 d7d5 b1c3 g8f6 e2e3
info depth 6 multipv 1 time 3 nps 3032666 score cp -1 nodes 9098 tbhits 0 pv d2d
4 d7d5 b1c3 g8f6 e2e3 e7e6
info depth 7 multipv 1 time 4 nps 3184000 score cp 2 nodes 12736 tbhits 0 pv d2d
4 d7d5 b1c3 g8f6 c1f4 e7e6 e2e3
info depth 8 multipv 1 time 5 nps 3073600 score cp -5 upperbound nodes 15368 tbh
its 0 pv d2d4 d7d5
info depth 8 multipv 1 time 5 nps 4043400 score cp -4 nodes 20217 tbhits 0 pv d2
d4 d7d5 g1f3 g8f6 c1f4 h7h6 e2e3 b8c6
info depth 9 multipv 1 time 7 nps 4473714 score cp 2 lowerbound nodes 31316 tbhi
ts 0 pv d2d4
info depth 9 multipv 1 time 8 nps 4225125 score cp 9 lowerbound nodes 33801 tbhi
ts 0 pv d2d4
info depth 9 multipv 1 time 9 nps 4118333 score cp 20 lowerbound nodes 37065 tbh
its 0 pv d2d4
info depth 9 multipv 1 time 11 nps 4540545 score cp 35 nodes 49946 tbhits 0 pv b
1c3 d7d5 d2d4 g8f6 g1f3 h7h6 e2e3 e7e6 h2h3
info depth 10 multipv 1 time 14 nps 4968428 score cp 28 upperbound nodes 69558 t
bhits 0 pv b1c3 d7d5
info depth 10 multipv 1 time 15 nps 5121200 score cp 21 upperbound nodes 76818 t
bhits 0 pv b1c3 d7d5
info depth 10 multipv 1 time 21 nps 5288904 score cp 14 nodes 111067 tbhits 0 pv
 g1f3 d7d5 d2d4 g8f6 e2e3 e7e6 f1d3 b8c6 e1g1 f8d6 c2c4 e8g8
info depth 11 multipv 1 time 27 nps 5548074 score cp 21 lowerbound nodes 149798
tbhits 0 pv g1f3
info depth 11 multipv 1 time 31 nps 5599870 score cp 29 lowerbound nodes 173596
tbhits 0 pv e2e4
info depth 11 multipv 1 time 31 nps 5678129 score cp 41 lowerbound nodes 176022
tbhits 0 pv e2e4
info depth 11 multipv 1 time 41 nps 5725512 score cp 30 upperbound nodes 234746
tbhits 0 pv e2e4 e7e5
info depth 11 multipv 1 time 51 nps 5828058 score cp 21 nodes 297231 tbhits 0 pv
 g1f3 d7d5 d2d4 g8f6 e2e3 e7e6 b1d2 f8d6 c2c4 c7c5 c4d5
info depth 12 multipv 1 time 55 nps 5764109 score cp 27 nodes 317026 tbhits 0 pv
 g1f3 d7d5 d2d4 g8f6 e2e3 e7e6 b1d2 b8c6 f1b5 f8d6 b5c6 b7c6 e1g1
info depth 13 multipv 1 time 65 nps 5876200 score cp 26 nodes 381953 tbhits 0 pv
 e2e4 e7e5 g1f3 g8f6 b1c3 b8c6 f1b5 f8c5 e1g1 e8g8 d2d3 d7d6 c1d2
info depth 14 multipv 1 time 150 nps 5946493 score cp 19 upperbound nodes 891974
 tbhits 0 pv e2e4 e7e5
info depth 14 multipv 1 time 170 nps 5932535 score cp 23 nodes 1008531 tbhits 0
pv e2e4 e7e5 g1f3 b8c6 f1c4 g8f6 d2d3 f8e7 e1g1 e8g8 b1c3 d7d6 d3d4 e5d4 f3d4
info depth 15 multipv 1 time 226 nps 5959154 score cp 16 upperbound nodes 134676
9 tbhits 0 pv e2e4 e7e5
info depth 15 multipv 1 time 314 nps 5955347 score cp 12 nodes 1869979 tbhits 0
pv e2e4 e7e5 g1f3 b8c6 d2d4 e5d4 f3d4 g8f6 d4c6 b7c6 e4e5 f6d5 c2c4 d5b6 d1e2 f8
e7 c1e3 d7d6 b1c3 d6e5
info depth 16 multipv 1 time 343 nps 5955475 score cp 19 lowerbound nodes 204272
8 tbhits 0 pv e2e4
info depth 16 multipv 1 time 477 nps 5941408 score cp 14 nodes 2834052 tbhits 0
pv g1f3 g8f6 d2d4 d7d5 c1f4 e7e6 e2e3 f8d6 f1d3 d6f4 e3f4 d8d6 b1d2 d6b4 e1g1 e8
g8 c2c3 b4b2
info depth 17 multipv 1 time 618 nps 5937972 score cp 21 lowerbound nodes 366966
7 tbhits 0 pv e2e4
info depth 17 multipv 1 time 729 nps 5934289 score cp 28 lowerbound nodes 432609
7 tbhits 0 pv e2e4
info depth 17 multipv 1 time 790 nps 5941500 score cp 23 nodes 4693785 tbhits 0
pv e2e4 e7e6 d2d4 d7d5 e4d5 e6d5 g1f3 g8f6 f1d3 f8e7 e1g1 e8g8 b1c3 c8g4 c1f4 f8
e8 f1e1 b8c6
info depth 18 multipv 1 time 1291 nps 5954975 score cp 16 upperbound nodes 76878
74 tbhits 0 pv e2e4 e7e6
info depth 18 multipv 1 time 1292 nps 5956849 score cp 21 nodes 7696249 tbhits 0
 pv e2e4 e7e6 d2d4 d7d5 e4d5 e6d5 g1f3 g8f6 f1d3 f8d6 e1g1 e8g8 b1c3 b8c6 c1g5 c
6b4 c3b5 h7h6 g5f6 d8f6 b5d6
info depth 19 multipv 1 time 1302 nps 5954848 score cp 21 nodes 7753213 tbhits 0
 pv e2e4 e7e6 d2d4 d7d5 e4d5 e6d5 g1f3 g8f6 f1d3 f8d6 e1g1 e8g8 b1c3 b8c6 c1g5 c
6b4 c3b5 h7h6 g5f6 d8f6 b5d6 f6d6
info depth 20 multipv 1 time 1390 nps 5947357 score cp 21 nodes 8266827 tbhits 0
 pv e2e4 e7e6 d2d4 d7d5 e4d5 e6d5 g1f3 g8f6 f1d3 f8d6 e1g1 e8g8 b1c3 b8c6 c1g5 c
6b4 c3b5 h7h6 g5f6 d8f6 b5d6 f6d6 f1e1
info depth 21 multipv 1 time 1883 nps 5923910 score cp 24 nodes 11154724 tbhits
0 pv e2e4 e7e6 d2d4 d7d5 e4d5 e6d5 g1f3 g8f6 f1d3 f8d6 e1g1 e8g8 b1c3 b8c6 c1g5
c6b4 c3b5 h7h6 g5f6 d8f6 b5d6 f6d6 c2c3 b4d3 d1d3
info depth 22 multipv 1 time 2506 nps 5912444 score cp 17 upperbound nodes 14816
585 tbhits 0 pv e2e4 e7e6
info depth 22 multipv 1 time 3825 nps 5875793 score cp 24 lowerbound nodes 22474
910 tbhits 0 pv d2d4
info depth 22 multipv 1 time 4815 nps 5850650 score cp 17 upperbound nodes 28170
881 tbhits 0 pv d2d4 d7d5
info depth 22 multipv 1 time 5578 nps 5832974 score cp 14 nodes 32536334 tbhits
0 pv d2d4 d7d5 c1f4 c8f5 e2e3 e7e6 g1f3 g8f6 f1e2 f8d6 f4d6 d8d6 b1d2 e8g8 f3h4
b8d7 h4f5 e6f5 e1g1 c7c5 c2c4 d6b6 c4d5 c5d4
info depth 23 multipv 1 time 9069 nps 5818288 score cp 21 lowerbound nodes 52766
054 tbhits 0 pv d2d4
info depth 23 multipv 1 time 9427 nps 5812410 score cp 14 upperbound nodes 54793
596 tbhits 0 pv d2d4 d7d5
info depth 23 multipv 1 time 10918 nps 5797896 score cp 13 nodes 63301433 tbhits
 0 pv d2d4 d7d5 g1f3 g8f6 e2e3 c7c5 f1e2 e7e6 e1g1 f8e7 c2c4 d5c4 e2c4 e8g8 b1c3
 a7a6 d4c5 e7c5 d1c2 c8d7 a2a3 b8c6 f1d1
info depth 24 multipv 1 time 19711 nps 5701586 score cp 11 nodes 112383966 tbhit
s 0 pv d2d4 d7d5 g1f3 g8f6 e2e3 e7e6 c2c4 c7c5 b1c3 b8c6 f1e2 c5d4 e3d4 f8e7 e1g
1 d5c4 e2c4 e8g8 a2a3 e7d6 c1g5 h7h6 g5f6 d8f6
info depth 25 multipv 1 time 26392 nps 5662708 score cp 18 lowerbound nodes 1494
50212 tbhits 0 pv d2d4
info depth 25 multipv 1 time 36771 nps 5611341 score cp 25 lowerbound nodes 2063
34641 tbhits 0 pv d2d4
info depth 25 multipv 1 time 42019 nps 5541086 score cp 28 nodes 232830920 tbhit
s 0 pv d2d4 d7d5 c2c4 e7e6 b1c3 g8f6 g1f3 f8e7 c1f4 e8g8 e2e3 b8c6 a2a3 a7a6 c4d
5 e6d5 f3e5 c8f5 e5c6 b7c6 f1e2 f8e8 e1g1 e7d6 f4g3 h7h6 g3d6 c7d6
Thread_Think returning
Thread_Think returning
Thread_Think returning
Thread_Think returning
bestmove d2d4 ponder d7d5
MainThread_Think returning


