#include<iostream>
#include <fstream>
#include <stdlib.h>
#include <ctime>
#include <sstream>
using namespace std;
#define SIZE 64
int main(int argc, char *argv[])
{
    ofstream out("test_case.dat");
    stringstream ss;
    int change_percent;
    srand(time(NULL));
    ss << argv[1];
    ss >> change_percent;
    cout << ("mutation rate = ") << change_percent << " %" << endl;
    out << "1 1 2 -1"<<endl;
    for (int i = 0; i < 500; i++)
    {
        
        char firstline[SIZE];
        for(int k =0;k<SIZE;k++){
           
            int r = rand() % 4;
                      
            if(r==0)           {
                firstline[k] = 'A';
                out << "A";
            } 
            else if(r==1)  {
                firstline[k] = 'T';
                out << "T";
            }     
            else if (r == 2)
            {
                firstline[k] = 'C';
                out << "C";
            }
            else if (r == 3)
            {
                firstline[k] = 'G';
                out << "G";
            }
        }
        out << "\n";

        // srand(time(NULL));
        for (int k = 0; k < SIZE; k++)
        {
            
            int r = rand() % 4;
            int r_2 = rand() % SIZE;

            if(r_2 < 0.2*change_percent){ // change
                if (r == 0)
                    out << "A";
                else if (r == 1)
                    out << "T";
                else if (r == 2)
                    out << "C";
                else if (r == 3)
                    out << "G";
            }
            else {      // not change
                out << firstline[k];
            }

        }
        out << "\n\n";
    }
    return 0;
}

// int random(){
//     srand(time(NULL));
//     int r = rand();
// }