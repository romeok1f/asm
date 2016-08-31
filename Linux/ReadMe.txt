The H.. version is special made for bulldozer, which puts two nodes in the same cpu.
Odd indexed nodes now use the same chm table as its even index partner. 01, 23, 45, 67
However, threads in node 1 are still pinned only to node 1, and threads in node 0 are still only pinned to node 0.
I assume you do not want the threads possibly jumping around.

Ouput from windows version on 1 node box

asmFishW_2016-08-31_bmi2
setoption name threads value 4
isready
info string node 0 cores 4 cmh 0x0000000001560000 group 0 mask 0x000000000000000f
info string node 0 has threads 0 1 2 3
readyok

if this is working correctly, node 1 should have the same cmh as node 0, node3 same as node2, ...


In an effort to reduce size, previous versions of asmFish are now in my asmFishBuilds repo.

If you observe a crash in asmFish, please raise an issue here and give me the following information:
  - name of the executable that crashed
  - exception code and exception offset
  - a log of the commands that were sent to asmFish by your gui before the crash
Simply stating that asmFish crashed in your gui is useless information by itself.
asmFish is known to have problems in the fritz15 gui, while it plays much better in the fritz11 gui.
Any help with this issue would be appreciated.
