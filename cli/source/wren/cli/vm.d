module wren.cli.vm;
import wren.vm;

import core.stdc.stdio;
import core.stdc.stdlib;
import wren.common;

__gshared WrenVM* vm;



// Reads the contents of the file at [path] and returns it as a heap allocated
// string.
//
// Returns `NULL` if the path could not be found. Exits if it was found but
// could not be read.
char* readFile(const char* path)
{
    FILE* file = fopen(path, "rb");
    if (file == null) return null;
    
    // Find out how big the file is.
    fseek(file, 0L, SEEK_END);
    size_t fileSize = ftell(file);
    rewind(file);
    
    // Allocate a buffer for it.
    char* buffer = cast(char*)malloc(fileSize + 1);
    if (buffer == null)
    {
        fprintf(stderr, "Could not read file \"%s\".\n", path);
        assert(0);
    }
    
    // Read the entire file.
    size_t bytesRead = fread(buffer, 1, fileSize, file);
    if (bytesRead < fileSize)
    {
        fprintf(stderr, "Could not read file \"%s\".\n", path);
        assert(0);
    }
    
    // Terminate the string.
    buffer[bytesRead] = '\0';
    
    fclose(file);
    return buffer;
}

void write(WrenVM* vm, const(char)* text)
{
    printf("%s", text);
}

void reportError(WrenVM* vm, WrenErrorType type,
                 const(char)* module_, int line, const(char)* message)
{
    switch (type) with(WrenErrorType)
    {
        case WREN_ERROR_COMPILE:
            fprintf(stderr, "[%s line %d] %s\n", module_, line, message);
            break;
        
        case WREN_ERROR_RUNTIME:
            fprintf(stderr, "%s\n", message);
            break;
        
        case WREN_ERROR_STACK_TRACE:
            fprintf(stderr, "[%s line %d] in %s\n", module_, line, message);
            break;
        default:
            assert(0, "Unhandled error");
    }
}

void initVM()
{
    WrenConfiguration config;
    wrenInitConfiguration(&config);

    config.writeFn = &write;
    config.errorFn = &reportError;

    // Since we're running in a standalone process, be generous with memory.
    config.initialHeapSize = 1024 * 1024 * 100;
    vm = wrenNewVM(&config);
}

void freeVM()
{
    wrenFreeVM(vm);
}

WrenInterpretResult runFile(const(char)* path)
{
    char* source = readFile(path);
    if (source == null)
    {
        fprintf(stderr, "Could not find file for \"%s\".\n", path);
        assert(0);
    }

    initVM();

    WrenInterpretResult result = wrenInterpret(vm, path, source);

    if (result == WrenInterpretResult.WREN_RESULT_SUCCESS)
    {
        // Stub
    }

    freeVM();
    
    free(source);

    return result;
}

WrenInterpretResult runRepl()
{
    initVM();

    printf("\\\\/\"-\n");
    printf(" \\_/   wren v%s\n", WREN_VERSION_STRING.ptr);

    WrenInterpretResult result = wrenInterpret(vm, "<repl>", "import \"repl\"\n");

    if (result == WrenInterpretResult.WREN_RESULT_SUCCESS)
    {
        assert(0, "Stub");
    }

    freeVM();

    return result;
}