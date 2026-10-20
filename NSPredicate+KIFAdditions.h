//
//  NSPredicate+T8nee.h
//  KIF
//
//  Created by Alex Odawa on 2/3/15.
//
//

#import <Foundation/Foundation.h>

@interface NSPredicate (T8nee)

@property NSString *kifPredicateDescription;

- (NSArray *)flatten;
- (NSCompoundPredicate *)minusSubpredicatesFrom:(NSPredicate *)otherPredicate;

@end
