#include <sys/stat.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

int main(int argc, const char **argv)
{
	int fd = open(argv[1], O_RDONLY);
	if (fd == -1) {
		return EXIT_FAILURE;
	}

	struct stat sb;
	if (fstat(fd, &sb) == -1) {
		close(fd);
		return EXIT_FAILURE;
	}

	void *addr = mmap(NULL, sb.st_size, PROT_READ, MAP_PRIVATE, fd, 0);
	if (addr == MAP_FAILED) {
		close(fd);
		return EXIT_FAILURE;
	}

	int result = remove(argv[1]);
	munmap(addr, sb.st_size);
	if (result != 0) {
		close(fd);
		return EXIT_FAILURE;
	}
	return 0;
}
