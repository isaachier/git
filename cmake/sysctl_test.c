#include <stdlib.h>
#include <sys/sysctl.h>
#include <sys/types.h>

int main()
{
	int mib[2] = { 0, 0 };
	size_t len = 0;
	int cpucount = 0;
	return sysctl(mib, 2, &cpucount, &len, NULL, 0);
}
