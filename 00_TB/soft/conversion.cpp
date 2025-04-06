#include <iostream>
#include <fstream>

using namespace std;

int main (int argc, char** argv) {
    fstream fin("./test_case.dat");
    fstream fout;
    fout.open("./test_case_hex.dat", ios::out);
    
    char c;
    int i = 0;
    
    while(fin >> c) {
        if (c == 'A') fout << "1 ";
        else if (c == 'T') fout << "2 ";
        else if (c == 'G') fout << "3 ";
        else if (c == 'C') fout << "4 ";
        i++;
        if (i == 31) {fout << '\n'; i = 0;}
    }

    return 0;
}
