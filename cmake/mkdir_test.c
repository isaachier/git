#include <sys/stat.h>
#include <sys/types.h>

int main(int argc, char* argv[])
{
	return mkdir(argv[1], S_IRWXO);
}
