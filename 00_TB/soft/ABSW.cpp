#include <iostream>
#include <fstream>
#include <time.h>

#define L 64
#define B 4

using namespace std;

int PE[B][2 * L - B];  // PEs
int o, e, match, mis;
int output[2];

void StorePE(int re_pos, int id, int addr, int mode);
int* Base(int H1, int D1, int H2, int I2, int H3, char Q, char R);

int main (int argc, char** argv) {
    char Q[L], R[L];     // input
    char Q_al[2 * L], R_al[2 * L]; // output
    long long int total_score = 0;
    
    // read files
    fstream fin(argv[1]);
    fstream fout;
    fout.open(argv[2], ios::out);
    fin >> o >> e >> match >> mis;
    double START, END;
    START = clock();
    
    while (fin >> Q[0]) {
        int i_al_start, j_al_start, i_al_finish, j_al_finish, max_score = 0; // output
        int id_finish, addr_finish;
        for (int i = 1; i < L; i++) fin >> Q[i];
        for (int i = 0; i < L; i++) fin >> R[i];
        //for (int i = 0; i < L; i++) fout << R[i];
        int D_p[B] = {0}, H_p[B] = {0}, I_p[B] = {0}, D[B] = {0}, H[B] = {0}, I[B] = {0}, H_p_p[B] = {0};
        char genes_Q[B] = {0}, genes_R[B] = {0}; // shift register
        int* tmp;

        for (int i = 0; i < B; i++) genes_Q[i] = Q[i];

        for (int i = 0; i < B; i++) {
            // parallelize
            
            genes_R[3] = genes_R[2];
            genes_R[2] = genes_R[1];
            genes_R[1] = genes_R[0];
            genes_R[0] = R[i];
            
            tmp = Base(H_p[0], D_p[0], 0, 0, 0, genes_Q[0], genes_R[0]);            // Max0
            D[0] = tmp[0]; I[0] = tmp[1]; H[0] = tmp[2];
            StorePE(tmp[3], 0, i, 2);

            if (i > 0) {                                                            // Max1
                tmp = Base(H_p[1], D_p[1], H_p[0], I_p[0], H_p_p[0], genes_Q[1], genes_R[1]);
                D[1] = tmp[0]; I[1] = tmp[1]; H[1] = tmp[2];
                StorePE(tmp[3], 1, i - 1, 2);
                                
            }

            if (i > 1) { // Max2
                tmp = Base(H_p[2], D_p[2], H_p[1], I_p[1], H_p_p[1], genes_Q[2], genes_R[2]);
                D[2] = tmp[0]; I[2] = tmp[1]; H[2] = tmp[2];
                StorePE(tmp[3], 2, i - 2, 2);

            }

            if (i > 2) { // Max3
                tmp = Base(H_p[3], D_p[3], H_p[2], I_p[2], H_p_p[2], genes_Q[3], genes_R[3]);
                D[3] = tmp[0]; I[3] = tmp[1]; H[3] = tmp[2];
                StorePE(tmp[3], 3, i - 3, 2);
            }

            for (int j = 0; j < B; j++) {
                D_p[j] = D[j];
                I_p[j] = I[j];
                H_p_p[j] = H_p[j];
                H_p[j] = H[j];
                if (H[j] > max_score) {
                    max_score = H[j];
                    id_finish = j;
                    addr_finish = i - j;
                }
            }
        }

        for (int i = B, type = 0; i < 2 * L - B; i++) {
            int input[5];
            //cout << type;
            if (!type) { // shift Q
                genes_Q[0] = genes_Q[1];
                genes_Q[1] = genes_Q[2];
                genes_Q[2] = genes_Q[3];
                genes_Q[3] = Q[i / 2 + 2];
            } else {
                genes_R[3] = genes_R[2];
                genes_R[2] = genes_R[1];
                genes_R[1] = genes_R[0];
                genes_R[0] = R[i / 2 + 2];
            }

            if(type) { input[0] = H_p[0]; input[1] = D_p[0]; input[2] = 0;      input[3] = 0;      input[4] = H_p_p[0]; } // Max0
            else     { input[0] = H_p[1]; input[1] = D_p[1]; input[2] = H_p[0]; input[3] = I_p[0]; input[4] = H_p_p[0]; }
            tmp = Base(input[0], input[1], input[2], input[3], input[4], genes_Q[0], genes_R[0]);
            D[0] = tmp[0]; I[0] = tmp[1]; H[0] = tmp[2];
            StorePE (tmp[3], 0, i, type);
            if(type) { input[0] = H_p[1]; input[1] = D_p[1]; input[2] = H_p[0]; input[3] = I_p[0]; input[4] = H_p_p[1]; } // Max1
            else     { input[0] = H_p[2]; input[1] = D_p[2]; input[2] = H_p[1]; input[3] = I_p[1]; input[4] = H_p_p[1]; }
            tmp = Base(input[0], input[1], input[2], input[3], input[4], genes_Q[1], genes_R[1]);
            D[1] = tmp[0]; I[1] = tmp[1]; H[1] = tmp[2];
            StorePE (tmp[3], 1, i - 1, type);
            
            if(type) { input[0] = H_p[2]; input[1] = D_p[2]; input[2] = H_p[1]; input[3] = I_p[1]; input[4] = H_p_p[2]; } // Max2
            else     { input[0] = H_p[3]; input[1] = D_p[3]; input[2] = H_p[2]; input[3] = I_p[2]; input[4] = H_p_p[2]; }
            tmp = Base(input[0], input[1], input[2], input[3], input[4], genes_Q[2], genes_R[2]);
            D[2] = tmp[0]; I[2] = tmp[1]; H[2] = tmp[2];
            StorePE (tmp[3], 2, i - 2, type);

            if(type) { input[0] = H_p[3]; input[1] = D_p[3]; input[2] = H_p[2]; input[3] = I_p[2]; input[4] = H_p_p[3]; } // Max1
            else     { input[0] = 0;      input[1] = 0;      input[2] = H_p[3]; input[3] = I_p[3]; input[4] = H_p_p[3]; }
            tmp = Base(input[0], input[1], input[2], input[3], input[4], genes_Q[3], genes_R[3]);
            D[3] = tmp[0]; I[3] = tmp[1]; H[3] = tmp[2];
            StorePE (tmp[3], 3, i - 3, type);

            for (int j = 0; j < B; j++) {
                D_p[j] = D[j];
                I_p[j] = I[j];
                H_p_p[j] = H_p[j];
                H_p[j] = H[j];
                if (H[j] > max_score) {
                    max_score = H[j];
                    id_finish = j;
                    addr_finish = i - j;
                }
            }
            if (type == 0) type = 1;
            else           type = 0;
        }

        for (int i = 2 * L - B; i < 2 * L; i++) {
            
            genes_R[3] = genes_R[2];
            genes_R[2] = genes_R[1];
            genes_R[1] = genes_R[0];
            genes_R[0] = genes_R[0];


            if (i < 2 * L - B) {         // Max0
                tmp = Base(H_p[0], D_p[0], 0, 0, 0, genes_Q[0], genes_R[0]);
                D[0] = tmp[0]; I[0] = tmp[1]; H[0] = tmp[2];
                StorePE(tmp[3], 0, i - 1, 2);
            }
                       
            if (i < 2 * L - B + 1) {    // Max1
                tmp = Base(H_p[1], D_p[1], H_p[0], I_p[0], H_p_p[0], genes_Q[1], genes_R[1]);
                D[1] = tmp[0]; I[1] = tmp[1]; H[1] = tmp[2];
                StorePE(tmp[3], 1, i - 1, 2);
            }
            
            if (i < 2 * L - B + 2) {
                tmp = Base(H_p[2], D_p[2], H_p[1], I_p[1], H_p_p[1], genes_Q[2], genes_R[2]);
                D[2] = tmp[0]; I[2] = tmp[1]; H[2] = tmp[2];
                StorePE(tmp[3], 2, i - 2, 2);               
            }
            
            if (i < 2 * L - B + 3) {
                //tmp = Base(H_p[1], D_p[1], H_p[0], I_p[0], H_p_p[2], genes_Q[3], genes_R[3]);
                tmp = Base(H_p[3], D_p[3], H_p[2], I_p[2], H_p_p[2], genes_Q[3], genes_R[3]);
                //cout << "H_p[1]: " << H_p[1] << "; H_p[3]: " << H_p[3] << endl;
                D[3] = tmp[0]; I[3] = tmp[1]; H[3] = tmp[2];
                StorePE(tmp[3], 3, i - 3, 2);
            }
            
            for (int j = 0; j < B; j++) {
                D_p[j] = D[j];
                I_p[j] = I[j];
                H_p_p[j] = H_p[j];
                H_p[j] = H[j];
                if (H[j] > max_score) {
                    max_score = H[j];
                    id_finish = j;
                    addr_finish = i - j;
                }
            }


        }
        /*for(int j = 0; j < B; j++) {
            for (int i = 0; i < 2 * L - B; i++) {
                cout << PE[j][i] << " ";
            } cout << endl;
        }*/

        int id_tb = id_finish;
        int addr_tb = addr_finish;
        int i_tb, j_tb;
        int i = 0;
        int flag = 1;
        int done = 0;
        
        // traceback
        while (!done) {
            if (addr_tb < B - id_tb) i_tb  = id_tb;
            else if (addr_tb >= 2 * L - B - id_tb) i_tb = L - B + id_tb;
            else i_tb = 1 + id_tb + (addr_tb- B+id_tb)/2;

            if (addr_tb < B - id_tb) j_tb  = addr_tb;
            else if (addr_tb >= 2 * L - B - id_tb) j_tb = addr_tb + B - L;
            else j_tb = B - id_tb - 1 + (addr_tb - B + id_tb + 1) / 2;

            switch (PE[id_tb][addr_tb]) {
                case 1: Q_al[i] = Q[i_tb]; R_al[i] = R[j_tb]; id_tb--; addr_tb--;  break;
                case 2: Q_al[i] = Q[i_tb]; R_al[i] = '-';     id_tb--;             break;
                case 3: Q_al[i] = '-';     R_al[i] = R[j_tb];          addr_tb--;  break;
                case 4: Q_al[i] = Q[i_tb]; R_al[i] = R[j_tb];          addr_tb-=2; break;
                case 5: Q_al[i] = Q[i_tb]; R_al[i] = '-';              addr_tb--;  break;
                case 6: Q_al[i] = '-';     R_al[i] = R[j_tb]; id_tb++; addr_tb-=2; break;
                default: Q_al[i] = Q[i_tb]; R_al[i] = R[j_tb];                     break;
            }
            if (flag) {
                i_al_finish = i_tb;
                j_al_finish = j_tb;
                flag = 0;
            }

            if (id_tb < 0 || addr_tb < 0 || PE[id_tb][addr_tb] == 0) done = 1;
            else    i++;  
        }
        if (PE[id_tb][addr_tb] == 0 && id_tb >= 0 && addr_tb >= 0) {
            Q_al[i] = Q[i_tb];
            R_al[i] = R[j_tb];
        }
        
        // outputs
        //fout << "Q_al: ";
        for (int m = i; m >= 0; m--) fout << Q_al[m];
        //fout << "\nR_al: ";
        fout << "\n";
        for (int m = i; m >= 0; m--) fout << R_al[m];
        //fout << "\ni_al_start: " << i_tb << endl << "j_al_start: " << j_tb << endl << "i_al_finish: " << i_al_finish << endl << "j_al_finish: " << j_al_finish << endl;
        fout << endl << i_tb << endl << j_tb << endl << i_al_finish << endl << j_al_finish << endl << max_score << endl;
        //fout << "score is  : " << max_score << endl;
        total_score += max_score;
    }
    cout << total_score << endl;
    END = clock();
    cout << (END-START) / CLOCKS_PER_SEC << endl;
    fin.close();
    fout.close();
    return 0;
}

void StorePE(int re_pos, int id, int addr, int mode) {
    if      (mode == 2 && re_pos == 0) PE[id][addr] = 0;
    else if (mode == 2 && re_pos == 1) PE[id][addr] = 2;
    else if (mode == 2 && re_pos == 2) PE[id][addr] = 1;
    else if (mode == 2 && re_pos == 3) PE[id][addr] = 3;    
    else if (mode == 1 && re_pos == 0) PE[id][addr] = 0;
    else if (mode == 1 && re_pos == 1) PE[id][addr] = 2;
    else if (mode == 1 && re_pos == 2) PE[id][addr] = 4;
    else if (mode == 1 && re_pos == 3) PE[id][addr] = 3;
    else if (mode == 0 && re_pos == 0) PE[id][addr] = 0;
    else if (mode == 0 && re_pos == 1) PE[id][addr] = 5;
    else if (mode == 0 && re_pos == 2) PE[id][addr] = 4;
    else if (mode == 0 && re_pos == 3) PE[id][addr] = 6;
 
}

int* Base(int H1, int D1, int H2, int I2, int H3, char Q, char R) {
    int D, I, H, re_pos = 0;
    int delta;

    delta = (Q == R) ? match : mis;
    D = (H1 - o > D1 - e) ? H1 - o : D1 - e;
    I = (H2 - o > I2 - e) ? H2 - o : I2 - e;
    H = 0;
    if (I > H) {H = I; re_pos = 1; }
    if (D > H) {H = D; re_pos = 3;}
    if (H3 + delta > H) {H = H3 + delta; re_pos = 2;}
    output[0] = D;
    output[1] = I;
    output[2] = H;
    output[3] = re_pos;
    return output;
}