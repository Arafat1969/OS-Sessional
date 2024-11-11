# OS-Sessional
Prerequisite tools: https://pdos.csail.mit.edu/6.828/2022/tools.html <br>
Cloning codebase:<br>
&npsb; &npsb; git clone https://github.com/shuaibw/xv6-riscv --depth=1 <br>
Compile and run (from inside xv6-riscv directory): <br>
make clean; make qemu <br>
Generating patch (from inside xv6-riscv directory): <br>
git add --all; git diff HEAD > <patch file name> <br>
e.g.: git add --all; git diff HEAD > ../test.patch <br>
Applying patch:<br>
git apply --whitespace=fix <patch file name><br>
e.g.: git apply --whitespace=fix ../test.patch<br>
Cleanup git directory:<br>
git clean -fdx; git reset --hard<br>
Explanation of source code (Not required for this course, but you may want to go through it):<br>
https://www.youtube.com/watch?v=fWUJKH0RNFE&list=PLbtzT1TYeoMhTPzyTZboW_j7TPAnj
v9XB <br>
