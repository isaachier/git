#include <time.h>

int main()
{
	time_t time = -1;
	return gmtime(&time) != NULL;
}
