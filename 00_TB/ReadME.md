output format:
Q_al:
R_al:
i_al_start:
j_al_start:
i_al_finish:
j_al_finish:
score:

Files:
    BSW_serial.v: Banded-Smith-Waterman verilog
    BSW_tb_serial.v: testbench
    pattern_g.cpp: test_case generator
    conversion.cpp: convert ATGC to 1234 for verilog to read
    compare.cpp: compare the files are same or not
    ABSW.cpp:    ABSW cpp file
Usage:
    1. Use pattern_g.cpp to generate test case
        command line: g++ -o pattern_g pattern_g.cpp
                      ./pattern_g 30 // 30 is mutation rate
    
    2. generate correct answer
        g++ -o ABSW ABSW.cpp
        ./ABSW test_case.dat out_ABSW.dat

    3. generate test case for verilog
        g++ -o convert conversion.cpp
        ./convert
    
    4. run verilog
        vcs ...
    
    5. verify result
        g++ -o compare compare.cpp
        ./compare