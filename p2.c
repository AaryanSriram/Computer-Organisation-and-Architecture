#include<stdio.h>
extern int decrypt(char* cipher_text); // forward declaration with arguments
extern char ans[]; // forward declaration
char* cipher_text = "kocvuzwyliuwslylkmlzvnclwylfbzlbok";
char substitution[] = {
'w', 't', 'z', 'f', 'v',
'i', 's', 'h', 'l', 'g',
'a', 'y', 'e', 'r', 'b',
'c', 'p', 'u', 'k', 'm',
'o', 'd', 'x', 'n', 'j',
'q'
};
char alphabet[] = {
    'a', 'b', 'c', 'd', 'e',
    'f', 'g', 'h', 'i', 'j',
    'k', 'l', 'm', 'n', 'o',
    'p', 'q', 'r', 's', 't',
    'u', 'v', 'w', 'x', 'y',
    'z'
};
int main(){
// call the decryption function from assembly
int num = decrypt(cipher_text);
printf("recovered␣plain␣text:␣%s\n", ans);
}