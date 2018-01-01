#include <stdio.h>

int main()
{
	char buf[1];
	return snprintf(&buf[0], sizeof(buf), "%d", 16);
}
