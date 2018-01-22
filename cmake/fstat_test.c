#include <fcntl.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

int main(int argc, const char **argv)
{
	int fd = open(argv[1], O_WRONLY);
	if (fd == -1) {
		return EXIT_FAILURE;
	}

	const char *data = "hello world\n";
	int data_length = strlen(data);
	ssize_t written = write(fd, data, data_length);
	if (written != data_length) {
		close(fd);
		return EXIT_FAILURE;
	}

	struct stat fstat_result;
	if (fstat(fd, &fstat_result) != 0) {
		close(fd);
		return EXIT_FAILURE;
	}

	close(fd);
	struct stat lstat_result;
	if (lstat(argv[1], &lstat_result) != 0) {
		return EXIT_FAILURE;
	}

	/* Only returns 0 if fstat_result != lstat_result */
	return (fstat_result.st_mtime != lstat_result.st_mtime) ||
		   (fstat_result.st_ctime != lstat_result.st_ctime);
}
