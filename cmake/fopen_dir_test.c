#include <stdio.h>

int main(int argc, char* argv[])
{
	FILE* f = fopen(argv[1], "r");
	if (f != NULL) {
		fclose(f);
		return 0;
	}
	return 1;
}
