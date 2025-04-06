`timescale 1ns/1ns
`define CYCLE    16
`define PATTERN  500
`define SIZE     64
`define IJ_WIDTH 7
`define SCORE_WIDTH 9
`define TEST     "./test/test_case_hex.dat"
`define SDFFILE    "./BSW.sdf"

module BandSW_test;

parameter DATA_LENGTH = `SIZE * 2 * `PATTERN;

reg  clk, rst, start;
reg  [ 2:0] i_Q, i_R;

wire done;
wire [ 2:0] Q_al, R_al;
wire [`SCORE_WIDTH - 1:0] detail_info;
reg  [3:0] case_mem [0: DATA_LENGTH - 1];
reg  [2:0] Q_al_mem [0: 2 * `SIZE - 1];
reg  [2:0] R_al_mem [0: 2 * `SIZE - 1];
reg  [`SCORE_WIDTH - 1:0] position_mem [0:4];
//reg  [2:0] o, e, match, mismatch;   // modify in .v file

integer i, j;
integer fp_r, fp_w;
integer total_score = 0;


BSW BSW0 (clk, rst, start, i_Q, i_R, Q_al, R_al, detail_info, done);

initial $readmemh(`TEST, case_mem);
initial fp_w = $fopen("data_out.dat", "w");

`ifdef SDF
initial $sdf_annotate(`SDFFILE, BSW0);
`endif  

initial begin
    clk = 1'b1;
    rst = 1'b0;
    for (i=0;i<`PATTERN;i=i+1) begin
        start = 0;
        #(`CYCLE / 4) rst = 1;
        #(`CYCLE * 3 / 4) rst = 0;
        for (j = 0; j < 2 * `SIZE; j = j + 1) begin
            Q_al_mem[j] = 0;
            R_al_mem[j] = 0;
        end
        #(`CYCLE / 2);
        start = 1;
        for (j = 0; j < `SIZE; j = j + 1) begin
            i_Q = case_mem[2 * `SIZE * i + j];
            i_R = case_mem[2 * `SIZE * i + j + `SIZE];
            #(`CYCLE);
        end
        #(`CYCLE);
        start = 0;

        wait(done);
        for (j = 0; Q_al != 0; j = j + 1) begin
            @(negedge clk);
            Q_al_mem[j] = Q_al;
            R_al_mem[j] = R_al;
            if (j < 5) position_mem[j] = detail_info;
        end
        $display(i);

        // write
        for (j = 0; Q_al_mem[j]; j = j + 1) begin
            if      (Q_al_mem[j] == 3'b001) $fwrite(fp_w, "A");
            else if (Q_al_mem[j] == 3'b010) $fwrite(fp_w, "T");
            else if (Q_al_mem[j] == 3'b011) $fwrite(fp_w, "G");
            else if (Q_al_mem[j] == 3'b100) $fwrite(fp_w, "C");
            else if (Q_al_mem[j] == 3'b101) $fwrite(fp_w, "-");         
        end
        //$fwrite(fp_w, "\nR_al: ");
        $fwrite(fp_w, "\n");
        for (j = 0; R_al_mem[j]; j = j + 1) begin
            if      (R_al_mem[j] == 3'b001) $fwrite(fp_w, "A");
            else if (R_al_mem[j] == 3'b010) $fwrite(fp_w, "T");
            else if (R_al_mem[j] == 3'b011) $fwrite(fp_w, "G");
            else if (R_al_mem[j] == 3'b100) $fwrite(fp_w, "C");
            else if (R_al_mem[j] == 3'b101) $fwrite(fp_w, "-");       
        end
        $fwrite(fp_w, "\n%g\n%g\n%g\n%g\n%g\n", position_mem[0], position_mem[1], position_mem[2], position_mem[3], position_mem[4]);
        total_score = total_score + position_mem[4];
        //$display(score);
    end
    $display(total_score);
    $finish;
end

always #(`CYCLE / 2) clk = ~clk;

initial begin
    $fsdbDumpfile("BSW.fsdb");
	$fsdbDumpvars;
	$fsdbDumpMDA;
end


endmodule
