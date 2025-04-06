`define A 3'b001
`define T 3'b010
`define G 3'b011
`define C 3'b100
`define D 3'b101 // Dash
`define SCORE_WIDTH 9
`define IJ_WIDTH    7
`define ID_WIDTH    5
`define ADDR_WIDTH  8
`define SIZE        64
`define B         6
//`define o   3'b001
//`define e   3'b001
//`define match 3'b010
//`define mismatch 3'b111


module BSW (
    clk, rst, start,
    i_Q, i_R,
    //i_score_param,
    o_Q_al,
    o_R_al,
    detail_info,
    done
);
    parameter IDLE     = 3'b000;
    parameter SCOR     = 3'b001;
    parameter TRBK     = 3'b010;
    parameter READ     = 3'b011;
    parameter DONE     = 3'b100;
    parameter o        = 3'b001;
    parameter e        = 3'b001;
    parameter match    = 3'b010;
    parameter signed mismatch = 3'b111;
    //parameter B = 6;

    integer  i;

    input clk, rst;
    input  [2:0] i_Q, i_R;
    input  start;
    //input  [3:0] B,
    //input [2:0] i_score_param;             // o, e, match, mismatch
    output [2:0] o_Q_al, o_R_al;
    output reg [`SCORE_WIDTH - 1:0] detail_info;          // i/j start/end, score
    output reg done;

    reg [1:0] type;
    reg [2:0] state, state_next;
    reg [`SCORE_WIDTH - 1:0] max_score;
    reg [6:0] counter_read, counter_read_next;
    reg [8:0] counter_scor, counter_scor_next;
    reg [9:0] counter_out, counter_out_next;
    reg [2:0] genes_Q [0:    `B - 1];
    reg [2:0] genes_R [0:    `B - 1];
    reg [2:0] Q       [0: `SIZE - 1];
    reg [2:0] R       [0: `SIZE - 1];
    reg [2:0] Q_next  [0: `SIZE - 1];
    reg [2:0] R_next  [0: `SIZE - 1];
    reg [2:0] Q_al    [0: `SIZE * 2 - 1];
    reg [2:0] R_al    [0: `SIZE * 2 - 1];
    reg [`ID_WIDTH   - 1:0] id_finish,   id_tb,   id_tb_next;
    reg [`ADDR_WIDTH - 1:0] addr_finish, addr_tb, addr_tb_next;
    reg [2:0] re_pos_tb;
    reg [`IJ_WIDTH - 1:0] i_tb, j_tb;
    reg [2:0] Q_al_in, R_al_in;
    wire [2:0] Q_al_tmp, R_al_tmp;
    reg wen [0: `B - 1];  // write enable of PEs
    reg [`ADDR_WIDTH  - 1:0] addr_RAM [0 : `B - 1];
    reg [`SCORE_WIDTH - 1:0] max_score_tmp [0 : `B - 2];
    reg [`ID_WIDTH    - 1:0] id_finish_tmp [0 : `B - 2];
    reg [`ADDR_WIDTH  - 1:0] addr_finish_next;
    reg [`SCORE_WIDTH - 1:0] max_score_next;
    reg [`ID_WIDTH    - 1:0] id_finish_next;
    reg [`IJ_WIDTH    - 1:0] i_start, j_start, i_finish, j_finish;
    reg signed [`SCORE_WIDTH - 1:0] H1    [0: `B - 1];
    reg signed [`SCORE_WIDTH - 1:0] H2    [0: `B - 1];
    reg signed [`SCORE_WIDTH - 1:0] H3    [0: `B - 1];
    reg signed [`SCORE_WIDTH - 1:0] D1    [0: `B - 1];
    reg signed [`SCORE_WIDTH - 1:0] I2    [0: `B - 1];
    reg signed [`SCORE_WIDTH - 1:0] D_p   [0: `B - 1];
    reg signed [`SCORE_WIDTH - 1:0] I_p   [0: `B - 1];
    reg signed [`SCORE_WIDTH - 1:0] H_p   [0: `B - 1];
    reg signed [`SCORE_WIDTH - 1:0] H_p_p [0: `B - 1];

    wire clk_Q, rst_Q;
    wire [2:0] o_data [0: `B - 1];
    wire [2:0] re_pos [0: `B - 1];
    wire [`IJ_WIDTH - 1:0] i_finish_next, j_finish_next;
    wire signed [`SCORE_WIDTH - 1:0] H [0: `B - 1];
    wire signed [`SCORE_WIDTH - 1:0] D [0: `B - 1];
    wire signed [`SCORE_WIDTH - 1:0] I [0: `B - 1];
    wire done_next;

    //wire clk_R;
    reg [2:0] genes_R_input;
    reg [2:0] genes_R_next[0: `B-1];

    // submodules (PE, RAM)
    genvar j;
    generate
        for (j = 0; j < `B; j = j + 1) begin: PEs_inst
            //PE PEs(H1[j], D1[j], H2[j], I2[j], H3[j], genes_Q[j], genes_R[j], o, e, match, mismatch, type, wen[j], D[j], I[j], H[j], re_pos[j]);
            PE PEs(H1[j], D1[j], H2[j], I2[j], H3[j], genes_Q[j], genes_R[j], type, wen[j], D[j], I[j], H[j], re_pos[j]);
        end
        
        for (j = 0; j < `B; j = j + 1) begin: RAMs_inst
            RAM RAMs (clk, rst, wen[j], addr_RAM[j], re_pos[j], o_data[j]);
        end
    endgenerate
    // 1: up, left;    2: up once;         3: left once
    // 4: left twice   5: left once trans  6: down, left twice
    // 0: self


    // FSM
    always@(*) begin
        case (state)
            IDLE:
                if (start) state_next = READ;
                else       state_next = IDLE;
            SCOR:
                if (counter_scor == 2 * `SIZE - 1) state_next = TRBK;
                else                               state_next = SCOR;
            TRBK:
                if (done_next) state_next = DONE;
                else      state_next = TRBK;
            READ:
                if (counter_read == (`SIZE - 2)) state_next = SCOR;
                else             state_next = READ;
            DONE:
                if (o_Q_al == 0) state_next = IDLE;
                else                            state_next = state;
            default: state_next = IDLE;
        endcase 
    end
    always@(posedge clk or posedge rst) begin
        if (rst) state <= IDLE;
        else     state <= state_next;
    end
    // FSM ends


    // read phase
    always@(*) begin
        if (state == READ) counter_read_next = counter_read + 1;
        else               counter_read_next = 0;
    end
    always@(posedge clk or posedge rst) begin
        if (rst) counter_read <= 0;
        else     counter_read <= counter_read_next;
    end

    

    // o, e, match, mismatch
    // reg [2:0] o, e, match, mismatch, o_next, e_next, match_next, mismatch_next;
    /*always@(*) begin
        if (counter_read == 0) o_next = i_score_param;
        else                   o_next = o;
        if (counter_read == 1) e_next = i_score_param;
        else                   e_next = e;
        if (counter_read == 2) match_next = i_score_param;
        else                   match_next = match;
        if (counter_read == 3) mismatch_next = i_score_param;
        else                   mismatch_next = mismatch;
    end
    always@(posedge clk or posedge rst) begin
        if (rst) begin
            o        <= 0;
            e        <= 0;
            match    <= 0;
            mismatch <= 0;
        end else begin
            o        <= o_next;
            e        <= e_next;
            match    <= match_next;
            mismatch <= mismatch_next;
        end
    end*/

    // Q, R  // modify to serial input
    always@(*) begin
        for (i = 0; i < `SIZE - 1; i = i + 1) begin
            if (state == READ) begin
                Q_next[i] = Q[i + 1];
                R_next[i] = R[i + 1];
            end else begin
                Q_next[i] = Q[i];
                R_next[i] = R[i];
            end
        end
    end
    always@(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < `SIZE; i = i + 1) begin
                Q[i] <= 0;
                R[i] <= 0;
            end 
        end else begin
            for (i = 0; i < `SIZE - 1; i = i + 1) begin
                Q[i] <= Q_next[i];
                R[i] <= R_next[i];
            end
            Q[`SIZE - 1] <= i_Q;
            R[`SIZE - 1] <= i_R;
        end
    end
    // read phase ends


    always @(*) begin
        for (i = 0; i < `B; i = i + 1) begin
            wen[i] = (counter_scor >= i && counter_scor < 2 * `SIZE - `B + i) && (state == SCOR);
            addr_RAM[i] = (state == SCOR) ? (counter_scor - i) : addr_tb_next;
        end
    end

    // scoring phase

    // genes_Q
    wire y;
    assign y = ((type == 1 && counter_scor != (2 * `SIZE - `B - 1)) || (type == 2 && counter_scor == `B - 1));
    reg [2:0] genes_Q_next [0:`B - 1];
    always@(*) begin
        if (y) begin
            for (i = 0; i < `B - 1; i = i + 1) genes_Q_next[i] = genes_Q[i + 1];
            genes_Q_next[`B - 1] = Q[((counter_scor - `B + 1) >> 1) + `B];
        end else if (state == READ) begin
            for (i = 0; i < `B; i = i + 1) genes_Q_next[i] = Q[i + 1];
        end else begin
            for (i = 0; i < `B; i = i + 1) genes_Q_next[i] = genes_Q[i];
        end

    end

    always@(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < `B; i = i + 1) genes_Q[i] <= 0;
        end else begin
            for (i = 0; i < `B; i = i + 1) genes_Q[i] <= genes_Q_next[i];
        end
    end


    // genes_R
    wire x;
    assign x = (type == 0 || type == 3 || (type == 2 && counter_scor != `B - 1) || (counter_scor == 2 * `SIZE - `B - 1));
    always@(*) begin                                // ne(e)d to modify in original version
        if (x) begin 
            for (i = 0; i < `B - 1; i = i + 1) begin
                genes_R_next[i + 1] = genes_R[i];
            end
            genes_R_next[0] = genes_R_input;
        end else begin
            for (i = 0; i < `B; i = i + 1)
                genes_R_next[i] = genes_R[i];      
        end
    end

    //assign genes_R_input = (counter_scor == 0) ? R_next[0] : (counter_scor < `B) ? R[counter_scor+1] : ((counter_scor < 2 * `SIZE - `B) ? R[(counter_scor >> 1) + 2] : genes_R[0]);
    always@(*) begin
        if (state == READ) genes_R_input = R_next[0];
        else if (state == SCOR && counter_scor < `B - 1) genes_R_input = R[counter_scor + 1];
        else genes_R_input = R[(counter_scor + `B) >> 1];
    
    end
    //assign clk_R = ((type == 2 && counter_scor != `B - 1) && clk) || (type == 1);

    always@(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < `B; i = i + 1)
                genes_R[i] <= 0;
        end else begin
            for (i = 0; i < `B; i = i + 1)
                genes_R[i] <= genes_R_next[i];
        end
    end


    // counter_scor
    always@(*) begin
        if (state == SCOR) counter_scor_next = counter_scor + 1;
        else               counter_scor_next = 0;
    end

    always@(posedge clk or posedge rst) begin
        if (rst)    counter_scor <= 0;
        else        counter_scor <= counter_scor_next;
    end

    // H1, D1
    always@(*) begin
        for (i = 0; i < `B - 1; i = i + 1) begin
            if (counter_scor < `B || counter_scor >= 2 * `SIZE - `B) begin
                H1[i] = H_p[i];
                D1[i] = D_p[i];
            end else if (type) begin
                H1[i] = H_p[i];
                D1[i] = D_p[i];
            end else begin
                H1[i] = H_p[i + 1];
                D1[i] = D_p[i + 1];
            end
        end
        if (counter_scor < `B || counter_scor >= 2 * `SIZE - `B) begin
            H1[`B - 1] = H_p[`B - 1];
            D1[`B - 1] = D_p[`B - 1];
        end else if (type) begin
            H1[`B - 1] = H_p[`B - 1];
            D1[`B - 1] = D_p[`B - 1];
        end else begin
            H1[`B - 1] = 0;
            D1[`B - 1] = 0;
        end
    end

    // H2, I2
    always@(*) begin
        for (i = 1; i < `B; i = i + 1) begin
            if (counter_scor < `B || counter_scor >= 2 * `SIZE - `B) begin
                H2[i] = H_p[i - 1];
                I2[i] = I_p[i - 1];
            end else if (type) begin
                H2[i] = H_p[i - 1];
                I2[i] = I_p[i - 1];
            end else begin
                H2[i] = H_p[i];
                I2[i] = I_p[i];
            end
        end
        if (counter_scor < `B || counter_scor >= 2 * `SIZE - `B) begin
            H2[0] = 0;
            I2[0] = 0;
        end else if (type) begin
            H2[0] = 0;
            I2[0] = 0;
        end else begin
            H2[0] = H_p[0];
            I2[0] = I_p[0];
        end
    end

    // H3
    always@(*) begin
        for (i = 1; i < `B; i = i + 1) begin
            if (counter_scor < `B || counter_scor >= 2 * `SIZE - `B)
                H3[i] = H_p_p[i - 1];
            else
                H3[i] = H_p_p[i];
        end
        if (counter_scor < `B || counter_scor >= 2 * `SIZE - `B) 
            H3[0] = 0;
        else
            H3[0] = H_p_p[0];
    end

    // D_p, I_p, H_p, H_p_p
    always@(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < `B; i = i + 1) begin
                D_p[i]   <= 0;
                I_p[i]   <= 0;
                H_p[i]   <= 0;
                H_p_p[i] <= 0;
            end
        end else begin
            for(i = 0; i < `B; i = i + 1) begin
                D_p[i]   <= D[i];
                I_p[i]   <= I[i];
                H_p[i]   <= H[i];
                H_p_p[i] <= H_p[i];
            end
        end
    end

    // type
    always@(*) begin
        if (state != SCOR) type = 2'b11;  // no type3
        else if (counter_scor >= `B && counter_scor < 2 * `SIZE - `B) type = {1'b0, counter_scor[0]};
        else               type = 2'b10;
    end

    // max_score
    always@(*) begin
        if (H[0] >= H[1]) begin 
            max_score_tmp[0]   = H[0];
            id_finish_tmp[0]   = 0;
        end else begin
            max_score_tmp[0]   = H[1];
            id_finish_tmp[0]   = 1;
        end
        
        for (i = 0; i < `B - 2; i = i + 1) begin
            if (max_score_tmp[i] >= H[i + 2]) begin
                max_score_tmp[i + 1] = max_score_tmp[i];
                id_finish_tmp[i + 1] = id_finish_tmp[i];
            end else begin
                max_score_tmp[i + 1] = H[i + 2];
                id_finish_tmp[i + 1] = i + 2;
            end
        end

        if (max_score_tmp[`B - 2] > max_score) begin
            max_score_next   = max_score_tmp[`B - 2];
            id_finish_next   = id_finish_tmp[`B - 2];
            addr_finish_next = counter_scor - id_finish_tmp[`B - 2];
        end else begin
            max_score_next   = max_score;
            id_finish_next   = id_finish;
            addr_finish_next = addr_finish;
        end
    end
/*    reg [`ID_WIDTH - 1:0] id_tmp[0:4];
    reg [`ADDR_WIDTH - 1:0] addr_tmp[0:4];
    reg signed [`SCORE_WIDTH - 1:0] max_tmp[0:4];

    always@(*) begin
        if (max_score >= H[0]) begin
            max_tmp[0]  = max_score;
            id_tmp[0]   = id_finish;
            addr_tmp[0] = addr_finish;
        end else begin
            max_tmp[0]  = H[0];
            id_tmp[0]   = 0;
            addr_tmp[0] = counter_scor;            
        end

        if (H[1] >= H[2]) begin
            max_tmp[1]  = H[1];
            id_tmp[1]   = 1;
            addr_tmp[1] = counter_scor - 1;      
        end else begin
            max_tmp[1]  = H[2];
            id_tmp[1]   = 2;
            addr_tmp[1] = counter_scor - 2;            
        end

        if (H[3] >= H[4]) begin
            max_tmp[2]  = H[3];
            id_tmp[2]   = 3;
            addr_tmp[2] = counter_scor - 3;      
        end else begin
            max_tmp[2]  = H[4];
            id_tmp[2]   = 4;
            addr_tmp[2] = counter_scor - 4;            
        end

        if (max_tmp[0] >= max_tmp[1]) begin
            max_tmp[3]  = max_tmp[0];
            id_tmp[3]   = id_tmp[0];
            addr_tmp[3] = addr_tmp[0];      
        end else begin
            max_tmp[3]  = max_tmp[1];
            id_tmp[3]   = id_tmp[1];
            addr_tmp[3] = addr_tmp[1];         
        end  

        if (max_tmp[2] >= H[5]) begin
            max_tmp[4]  = max_tmp[2];
            id_tmp[4]   = id_tmp[2];
            addr_tmp[4] = addr_tmp[2];      
        end else begin
            max_tmp[4]  = H[5];
            id_tmp[4]   = 5;
            addr_tmp[4] = counter_scor - 5;      
        end

        if (max_tmp[3] >= max_tmp[4]) begin
            max_score_next = max_tmp[3];
            id_finish_next = id_tmp[3];
            addr_finish_next = addr_tmp[3];     
        end else begin
            max_score_next = max_tmp[4];
            id_finish_next = id_tmp[4];
            addr_finish_next = addr_tmp[4];            
        end 

    end*/

    always@(posedge clk or posedge rst) begin
        if (rst) begin
            max_score   <= 0;
            id_finish   <= 0;
            addr_finish <= 0;
        end else begin
            max_score   <= max_score_next;
            id_finish   <= id_finish_next;
            addr_finish <= addr_finish_next;
        end
    end
    // scoring phase ends


    // traceback phase
    // re_pos_tb


    always@(*) begin
        re_pos_tb = 3'b000;
        for (i = 0; i < `B; i = i + 1)
            if (id_tb == i) re_pos_tb = o_data[i];
    end

    // id_tb
    always@(*) begin
        if (state == SCOR && state_next == TRBK) id_tb_next = id_finish;
        else if (re_pos_tb == 1) id_tb_next = id_tb - 1;
        else if (re_pos_tb == 2) id_tb_next = id_tb - 1;
        else if (re_pos_tb == 3) id_tb_next = id_tb;
        else if (re_pos_tb == 4) id_tb_next = id_tb;
        else if (re_pos_tb == 5) id_tb_next = id_tb;
        else if (re_pos_tb == 6) id_tb_next = id_tb + 1;
        else if (re_pos_tb == 0) id_tb_next = id_tb;
        else if (re_pos_tb == 7) id_tb_next = id_tb;
        else                     id_tb_next = 0;
    end
    

    // addr_tb
    always@(*) begin
        if (state == SCOR && state_next == TRBK) addr_tb_next = addr_finish;
        else if (re_pos_tb == 1) addr_tb_next = addr_tb - 1;
        else if (re_pos_tb == 2) addr_tb_next = addr_tb;
        else if (re_pos_tb == 3) addr_tb_next = addr_tb - 1;
        else if (re_pos_tb == 4) addr_tb_next = addr_tb - 2;
        else if (re_pos_tb == 5) addr_tb_next = addr_tb - 1;
        else if (re_pos_tb == 6) addr_tb_next = addr_tb - 2;
        else if (re_pos_tb == 0) addr_tb_next = addr_tb;
        else if (re_pos_tb == 7) addr_tb_next = addr_tb;
        else                     addr_tb_next = 0;
    end

    // id, addr to i, j converter
    always@(*) begin
        if (state != TRBK && state != DONE) begin
            i_tb = 0;
            j_tb = 0;
        end else if (addr_tb < `B - id_tb) begin
            i_tb = id_tb;
            j_tb = addr_tb;
        end else if (addr_tb >= 2 * `SIZE - `B - id_tb) begin
            i_tb = `SIZE - `B + id_tb;
            j_tb = addr_tb + `B - `SIZE;
        end else begin
            i_tb = (1 + id_tb) + ((addr_tb - (`B - id_tb)) >> 1);
            j_tb = (`B - id_tb - 1) + ((addr_tb - (`B - id_tb - 1)) >> 1);
        end
    end

    // Q_al_tmp, R_al_tmp                      // also need to modify in original version
    /*always@(*) begin
        Q_al_tmp = 3'b000;                       // default
        R_al_tmp = 3'b000;                       // default
        for (i = 0; i < `SIZE; i = i + 1) begin
            if (i_tb == i && state == TRBK) Q_al_tmp = Q[i];
            if (j_tb == i && state == TRBK) R_al_tmp = R[i];
        end
    end*/

    //assign Q_al_tmp = (state == TRBK) ? Q[i_tb] : 0;
    //assign R_al_tmp = (state == TRBK) ? R[j_tb] : 0;
    // assign Q_al_tmp = Q[i_tb];
    // assign R_al_tmp = R[j_tb];

    // Q_al_in, R_al_in
    always@(*) begin
        case (re_pos_tb) 
            3'b000:  begin Q_al_in = Q[i_tb]; R_al_in = R[j_tb]; end
            3'b001:  begin Q_al_in = Q[i_tb]; R_al_in = R[j_tb]; end
            3'b010:  begin Q_al_in = Q[i_tb]; R_al_in = 3'd5;    end
            3'b011:  begin Q_al_in = 3'd5;    R_al_in = R[j_tb]; end
            3'b100:  begin Q_al_in = Q[i_tb]; R_al_in = R[j_tb]; end
            3'b101:  begin Q_al_in = Q[i_tb]; R_al_in = 3'd5;    end
            3'b110:  begin Q_al_in = 3'd5;    R_al_in = R[j_tb]; end
            default: begin Q_al_in = 3'd0;    R_al_in = 3'd0;    end
        endcase
    end

    // Q_al, R_al by shift register
    reg [2:0] Q_al_next    [0: `SIZE * 2 - 1];
    reg [2:0] R_al_next    [0: `SIZE * 2 - 1];

    always@(*) begin
        if (state == DONE) begin
            for (i = 0; i < `SIZE * 2; i = i + 1) begin
                Q_al_next[i] = Q_al[i];
                R_al_next[i] = R_al[i];
            end
        end else begin
            for (i = 1; i < `SIZE * 2; i = i + 1) begin
                Q_al_next[i] = Q_al[i - 1];
                R_al_next[i] = R_al[i - 1];
            end
            Q_al_next[0] = Q_al_in;
            R_al_next[0] = R_al_in;
        end
    end
    always@(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < `SIZE * 2; i = i + 1) begin
                Q_al[i] <= 0;
                R_al[i] <= 0;
            end
        end else begin
            for (i = 0; i < `SIZE * 2; i = i + 1) begin
                Q_al[i] <= Q_al_next[i];
                R_al[i] <= R_al_next[i];
            end
        end
    end

    
    always@(*) begin
        if (state == DONE) counter_out_next = counter_out + 1;
        else               counter_out_next = 0;
    end
    always@(posedge clk or posedge rst) begin
        if (rst) counter_out <= 0;
        else     counter_out <= counter_out_next;
    end

//    assign o_Q_al = (state == DONE) ? Q_al[counter_out] : 0;
//    assign o_R_al = (state == DONE) ? R_al[counter_out] : 0;

    assign o_Q_al = Q_al[counter_out];
    assign o_R_al = R_al[counter_out];

    // i_start, j_start, i_finish, j_finish
    assign i_finish_next = (counter_scor == 2 * `SIZE) ? i_tb : i_finish;
    assign j_finish_next = (counter_scor == 2 * `SIZE) ? j_tb : j_finish;

    always@(*) begin
        case (counter_out)
            11'd0: detail_info = {3'b0, i_start};
            11'd1: detail_info = {3'b0, j_start};
            11'd2: detail_info = {3'b0, i_finish};
            11'd3: detail_info = {3'b0, j_finish};
            11'd4: detail_info = max_score;
            default: detail_info = 0;
        endcase
    end

    always@(posedge clk or posedge rst) begin
        if (rst) begin
            id_tb    <= 0;
            addr_tb  <= 0;
            i_start  <= 0;
            j_start  <= 0;
            i_finish <= 0;
            j_finish <= 0;
            done     <= 0;
        end else begin
            id_tb    <= id_tb_next;
            addr_tb  <= addr_tb_next;
            i_start  <= i_tb;
            j_start  <= j_tb;
            i_finish <= i_finish_next;
            j_finish <= j_finish_next;
            done     <= done_next;
        end
    end

    // done
    //assign done_next = ((re_pos_tb == 0) || (i_tb == 0) || (j_tb == 0)) && (state == TRBK);
    assign done_next = (re_pos_tb == 0 || (i_tb == 0 && re_pos_tb == 2) || (i_tb == 0 && re_pos_tb == 1) || (j_tb == 0 && re_pos_tb == 3) || (j_tb == 0 && re_pos_tb == 1)) && (state == TRBK || state == DONE);

endmodule

module PE (
    input signed [`SCORE_WIDTH - 1:0] H1, D1, H2, I2, H3, 
    input signed [2:0] Q, R, 
    input [1:0] type,
    input enable,
    output signed [`SCORE_WIDTH - 1:0] D, I, H,
    output reg [2:0] re_pos
);
    parameter signed o        = 3'b001;
    parameter signed e        = 3'b001;
    parameter signed match    = 3'b010;
    parameter signed mismatch = 3'b111;

    wire signed [2:0] delta;
    wire signed [`SCORE_WIDTH - 1:0] tmp1, tmp2;
    wire signed [2:0] tmp3, tmp4;
    wire [1:0] re_pos_tmp;

    assign D = (!enable) ? 0 : ((H1 - o > D1 - e) ? H1 - o : D1 - e);
    assign I = (!enable) ? 0 : ((H2 - o > I2 - e) ? H2 - o : I2 - e);
    assign delta = (Q == R) ? match : mismatch;
    assign tmp1 = (0 >= I) ? 0 : I;
    assign tmp2 = (D >= H3 + delta) ? D : H3 + delta;
    assign tmp3 = (0 >= I) ? 0 : 2'd1;
    assign tmp4 = (D >= H3 + delta) ? 2'd3 : (H3 == 0 ? 2'd0 : 2'd2);
    assign H = (!enable) ? 0 : ((tmp1 >= tmp2) ? tmp1 : tmp2);
    assign re_pos_tmp = (tmp1 >= tmp2) ? tmp3 : tmp4;
    always@(*) begin
        case ({type, re_pos_tmp})
            4'b0000: re_pos = 3'd0;
            4'b0001: re_pos = 3'd5;
            4'b0010: re_pos = 3'd4;
            4'b0011: re_pos = 3'd6;
            4'b0100: re_pos = 3'd0;
            4'b0101: re_pos = 3'd2;
            4'b0110: re_pos = 3'd4;
            4'b0111: re_pos = 3'd3;
            4'b1000: re_pos = 3'd0;
            4'b1001: re_pos = 3'd2;
            4'b1010: re_pos = 3'd1;
            4'b1011: re_pos = 3'd3;
            default: re_pos = 3'b000;
        endcase
    end
endmodule

module RAM (
    input clk, rst,
    input wen,
    input  [`ADDR_WIDTH - 1:0] addr,
    input  [2:0] i_data,
    output reg [2:0] o_data
);
    //parameter `B = 6;
    integer i;

    reg [2:0] m [0:2*`SIZE-`B-1];
    reg [2:0] m_next [0:2*`SIZE-`B-1];
    reg [2:0] o_data_next;

    always@(*) begin
        for (i=0;i<2*`SIZE-`B;i=i+1) begin
            m_next[i] = (wen && (i == addr)) ? i_data : m[i];
        end
    end

    always@(*) begin
        o_data_next = 3'b111;
        for (i=0;i<2*`SIZE-`B;i=i+1) begin
            if (i == addr) o_data_next = m[i];
        end
    end


    always@(posedge clk or posedge rst) begin
        if (rst) begin
            for (i=0;i<2*`SIZE-`B;i=i+1) begin
                m[i] <= 0;
            end
            o_data <= 0;
        end else begin
            for (i=0;i<2*`SIZE-`B;i=i+1) begin
                m[i] <= m_next[i];
            end
            o_data <= o_data_next;
        end
    end
endmodule