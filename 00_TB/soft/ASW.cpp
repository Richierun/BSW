#include <iostream>
#include <fstream>
#include <time.h>

using namespace std;
#define L 64
#define B 4

int main (int argc, char** argv) {
    int H[L + 1][L + 1];
    int D[L + 1][L + 1];
    int I[L + 1][L + 1];
    int T[L][L];
    int o, e, match, mismatch;
    char Q[L], R[L], Q_al[2*L], R_al[2*L];
    long long int total_score = 0;

    fstream fin(argv[1]);
    fstream fout;
    fout.open(argv[2], ios::out);
    fin >> o >> e >> match >> mismatch;
    double START, END;
    START = clock();
    while (fin >> Q[0]) {
        int max_score = 0;
        int i_al_start = 0, j_al_start = 0, i_al_finish = 0, j_al_finish = 0;

        for (int i = 1; i < L; i++) fin >> Q[i];
        for (int i = 0; i < L; i++) fin >> R[i];

        for (int i = 0; i < L + 1; i++) {
            H[0][i] = 0;
            H[i][0] = 0;
            D[0][i] = 0;
            D[i][0] = 0;
            I[0][i] = 0;
            I[i][0] = 0;
        }
        for (int i = 1; i < L + 1; i++) {
            for (int j = 1; j < L + 1; j++) {
                D[i][j] = (H[i][j-1] - o > D[i][j-1] - e) ? H[i][j-1] - o : D[i][j-1] - e;
                I[i][j] = (H[i-1][j] - o > I[i-1][j] - e) ? H[i-1][j] - o : I[i-1][j] - e;
                H[i][j] = 0;
                T[i - 1][j - 1] = 0;
                if (I[i][j] > H[i][j]) { H[i][j] = I[i][j]; T[i - 1][j - 1] = 1;}
                if (D[i][j] > H[i][j]) { H[i][j] = D[i][j]; T[i - 1][j - 1] = 3;}
                if (R[j-1] == Q[i-1] && (H[i-1][j-1] + match > H[i][j])) { H[i][j] = H[i-1][j-1] + match; T[i - 1][j - 1] = 2;}
                if (R[j-1] != Q[i-1] && (H[i-1][j-1] + mismatch > H[i][j])) { H[i][j] = H[i-1][j-1] + mismatch; T[i - 1][j - 1] = 2;}
                if (H[i][j] > max_score) {
                    max_score = H[i][j];
                    i_al_finish = i - 1;
                    j_al_finish = j - 1;
                }
            }
        }
        int i_tb = i_al_finish, j_tb = j_al_finish;
        int i = 0;
        while (1) {
            if (T[i_tb][j_tb] == 2) {
                Q_al[i] = Q[i_tb];
                R_al[i] = R[j_tb];
                if (i_tb == 0 || j_tb == 0) break;
                i_tb--;
                j_tb--;
                if(T[i_tb][j_tb] == 0) {i_tb++; j_tb++; break;}
                i++;
            } else if (T[i_tb][j_tb] == 1) {
                Q_al[i] = Q[i_tb];
                R_al[i] = '-';
                if (i_tb == 0) break;
                i_tb--;
                if(T[i_tb][j_tb] == 0) {i_tb++; break;}
                i++;
            } else if (T[i_tb][j_tb] == 3) {
                Q_al[i] = '-';
                R_al[i] = R[j_tb];
                if (j_tb == 0) break;
                j_tb--;
                if(T[i_tb][j_tb] == 0) {j_tb++; break;}
                i++;
            } else if (T[i_tb][j_tb] == 0) {
                Q_al[i] = Q[i_tb];
                R_al[i] = R[j_tb];
                break;
            }
        }
        fout << "Q_al: ";
        for (int m = i - 1; m >= 0; m--) fout << Q_al[m];
        fout << "\nR_al: ";
        for (int m = i - 1; m >= 0; m--) fout << R_al[m];
        fout << "\nj_al_start: " << j_tb << endl << "i_al_start: " << i_tb << endl << "j_al_finish: " << j_al_finish << endl << "i_al_finish: " << i_al_finish << endl;
        fout << "score is: " << max_score << endl;
        total_score += max_score;
    }
    cout << total_score << endl;
    END = clock();
    cout << (END-START) / CLOCKS_PER_SEC << endl;
    fin.close();
    fout.close();
    /*cout << "D:\n";
    for (int i = 0; i < L + 1; i++) {
        for (int j = 0; j < L + 1; j++) {

            if (D[i][j] < 0) cout << " ";
            else cout << "  ";
                        cout << D[i][j];
        }
        cout << endl;
    }

    cout << "I:\n";
    for (int i = 0; i < L + 1; i++) {
        for (int j = 0; j < L + 1; j++) {

            if (I[i][j] < 0) cout << " ";
            else cout << "  ";
                        cout << I[i][j];
        }
        cout << endl;
    }

    cout << "H:\n";
    for (int i = 0; i < L + 1; i++) {
        for (int j = 0; j < L + 1; j++) {
            cout << H[i][j] << " ";
        }
        cout << endl;
    }

    cout << "T:\n";
    for (int i = 0; i < L; i++) {
        for (int j = 0; j < L; j++) {
            cout << T[i][j] << " ";
        }
        cout << endl;
    }*/
    return 0;
}