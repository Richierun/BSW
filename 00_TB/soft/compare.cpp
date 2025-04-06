#include <iostream>
#include <fstream>
#include <string>

using namespace std;

int main (int argc, char** argv) {
    fstream fin1("../data_out.dat");
    fstream fin2("./out_ABSW.dat");
    string q1, q2, r1, r2;
    int is1, js1, if1, jf1, is2, js2, if2, jf2;
    int score1, score2;
    bool flag = 0;
    while (fin1 >> q1) {
        //cout << q1;
        fin1 >>       r1 >> is1 >> js1 >> if1 >> jf1 >> score1;
        fin2 >> q2 >> r2 >> is2 >> js2 >> if2 >> jf2 >> score2;
        
        if (q1 != q2) {
            cout << "q not the same" << endl;
            flag = 1;
            break;
        }
        if (r1 != r2) {
            cout << "r not the same" << endl;
            flag = 1;
            break;
        }
        if (is1 != is2) {
            cout << "is not the same" << endl;
            flag = 1;
            break;
        }
        if (js1 != js2) {
            cout << "js not the same" << endl;
            flag = 1;
            break;
        }
        if (if1 != if2) {
            cout << "if not the same" << endl;
            flag = 1;
            break;
        }
        if (jf1 != jf2) {
            cout << "jf not the same" << endl;
            flag = 1;
            break;
        }
        if (score1 != score2) {
            cout << "score not the same" << endl;
            flag = 1;
            break;
        }
    }
    if (flag == 0) cout << "the same !!!" << endl;
    else cout << q1 << endl<< q2 << endl;

    return 0;
}