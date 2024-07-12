#include <stdio.h>
#include "func.h"

int main(){
    int a=1;
    int b=2;
    printf("%d+%d=%d\n", a, b, add(a, b));
    return 0;
}