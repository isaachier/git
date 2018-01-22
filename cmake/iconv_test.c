#include <iconv.h>
#include <stdlib.h>

int main()
{
    iconv_t cd = NULL;
    CONST char* in_buf = NULL;
    size_t in_bytes_left = 0;
    size_t out_bytes_left = 0;
    char* out_buf = NULL;
    iconv(cd, &in_buf, &in_bytes_left, &out_buf, &out_bytes_left);
	return 0;
}
