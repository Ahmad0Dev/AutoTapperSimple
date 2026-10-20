#import <Foundation/Foundation.h>

// فك تشفير UTF-8 XOR
NS_INLINE NSString* _d(const char *hex) {
    size_t len = strlen(hex) / 2;
    uint8_t *bytes = (uint8_t *)malloc(len + 1);
    for (size_t i = 0; i < len; i++) {
        char b[3] = {hex[i*2], hex[i*2+1], 0};
        bytes[i] = (uint8_t)(strtol(b, NULL, 16) ^ 0x5A);
    }
    bytes[len] = 0;
    NSString *result = [[NSString alloc] initWithBytes:bytes length:len encoding:NSUTF8StringEncoding];
    free(bytes);
    return result ?: @"";
}

#define AT(hex) _d(hex)
