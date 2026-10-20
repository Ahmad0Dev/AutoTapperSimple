//
//  NSException-T8nee.h
//  KIF
//
//  Created by Tony DiPasquale on 12/20/13.
//
//

#import <Foundation/Foundation.h>

@interface NSException (T8nee)

+ (NSException *)failureInFile:(NSString *)file atLine:(NSInteger)line withDescription:(NSString *)formatString, ...;

@end
