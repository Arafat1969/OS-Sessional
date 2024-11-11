# OS-Sessional
### Prerequisite tools:<br>
 &nbsp; &nbsp; &nbsp;&nbsp; https://pdos.csail.mit.edu/6.828/2022/tools.html <br>
### Cloning codebase:<br>
 &nbsp; &nbsp; &nbsp; &nbsp;git clone https://github.com/shuaibw/xv6-riscv --depth=1 <br>
### Compile and run (from inside xv6-riscv directory): <br>
&nbsp; &nbsp; &nbsp; &nbsp; make clean; make qemu <br>
### Generating patch (from inside xv6-riscv directory): <br>
&nbsp; &nbsp; &nbsp; &nbsp; git add --all; git diff HEAD > <patch file name> <br>
&nbsp; &nbsp; &nbsp; &nbsp; e.g.: git add --all; git diff HEAD > ../test.patch <br>
### Applying patch:<br>
&nbsp; &nbsp; &nbsp; &nbsp;git apply --whitespace=fix <patch file name><br>
&nbsp; &nbsp; &nbsp; &nbsp; e.g.: git apply --whitespace=fix ../test.patch<br>
### Cleanup git directory:<br>
&nbsp; &nbsp; &nbsp; &nbsp;git clean -fdx; git reset --hard<br>
### Explanation of source code :<br>
&nbsp; &nbsp; &nbsp; &nbsp;https://www.youtube.com/watch?v=fWUJKH0RNFE&list=PLbtzT1TYeoMhTPzyTZboW_j7TPAnj
v9XB <br>
