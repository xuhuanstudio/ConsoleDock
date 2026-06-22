#include "SampleCLogging.h"

#include <stdio.h>

void SampleLogPrintf(const char *message)
{
    printf("%s\n", message);
    fflush(stdout);
}

void SampleLogFprintfStderr(const char *message)
{
    fprintf(stderr, "%s\n", message);
    fflush(stderr);
}
