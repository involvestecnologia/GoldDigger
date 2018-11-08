//
// Created by Felipe Lobo on 2018-11-02.
//

#import <ObjectiveSugar/ObjectiveSugar.h>
#import "GDGConditionParser.h"
#import "GDGCondition.h"
#import "GDGQuery.h"
#import "GDGQueryParser.h"
#import "NSError+GDG.h"

@implementation GDGConditionParser

- (GDGParsingResult *)parse:(GDGCondition *)conditionObject error:(NSError **)error
{
	NSMutableString *condition = [NSMutableString string];
	NSMutableArray *args = [NSMutableArray array];

	NSArray *operatorTokens = @[@"=", @">", @">=", @"<", @"<=", @"<>"];
	NSDictionary *fields = conditionObject.fields;
	NSMutableArray *tokens = conditionObject.tokens.mutableCopy;
	NSMutableDictionary *conditionArgs = conditionObject.args.mutableCopy;

	for (NSUInteger i = 0; i < tokens.count; i++)
	{
		NSString *__const token = tokens[i];

		if ([token isEqualToString:@"("])
			[condition appendString:@"("];
		else if ([token isEqualToString:@")"])
			[condition appendString:@")"];
		else if ([token hasPrefix:@"FIELD_"])
			[condition appendString:[(id <GDGConditionField>) fields[token] fullName]];
		else if ([operatorTokens containsObject:token])
			[condition appendString:token];
		else if ([token isEqualToString:@"IN"])
		{
			[condition appendString:@" IN ("];

			NSString *__const nextToken = tokens[++i];

			if ([nextToken hasPrefix:@"ARG_"])
			{
				id arg = conditionArgs[nextToken];

				if ([arg isKindOfClass:[NSString class]])
					[condition appendString:arg];
				else if ([arg isKindOfClass:[NSArray class]])
					[condition appendString:[[(NSArray *) arg map:^id(id object) {
						return NSStringWithFormat(@"%@", object);
					}] join:@", "]];
				else if ([arg isKindOfClass:[GDGQuery class]])
				{
					GDGQueryParser *qParser = [[GDGQueryParser alloc] init];

					NSError *underlyingError;
					GDGRawQuery *query = [qParser parse:arg error:&underlyingError];

					if (!query && underlyingError)
					{
						if (error)
						{
							NSString *message = NSStringWithFormat(@"Error while parsing a query condition for arg %@", nextToken);
							*error = [NSError errorWithCode:GDGParseArgumentConditionError
													message:message
												 underlying:underlyingError];
						}

						return nil;
					}

					[condition appendString:query.visit];
					[args addObjectsFromArray:query.args];
				}
				else if (error)
				{
					NSString *argClass = NSStringFromClass([arg class]);
					NSString *message = NSStringWithFormat(@"[SQLQuery -visit] thorws that the argument kind \"%@\" can't be interpreted", argClass)

					*error = [NSError errorWithCode:GDGParseUnknownArgumentKindError
											message:message
										 underlying:nil];

					return nil;
				}
			}

			[condition appendString:@")"];
		}
		else if ([token hasPrefix:@"ARG_"])
		{
			id arg = conditionArgs[token];
			[condition appendString:@"?"];
			[args addObject:arg];
		}
		else if ([token isEqualToString:@"AND"] && [condition length] > 0)
			[condition appendString:@"AND"];
		else if ([token isEqualToString:@"OR"] && [condition length] > 0)
			[condition appendString:@"OR"];
		else if ([token isEqualToString:@"NULL"])
			[condition appendString:@"IS NULL"];
		else if ([token isEqualToString:@"NOTNULL"])
			[condition appendString:@"IS NOT NULL"];

		[condition appendString:@" "];
	}

	[condition replaceCharactersInRange:NSMakeRange(condition.length - 1, 1) withString:@""];

	GDGParsingResult *result = [[GDGParsingResult alloc] init];
	result.visit = [NSString stringWithString:condition];
	result.args = [NSArray arrayWithArray:args];

	return result;
}

@end
