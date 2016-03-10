//
//  GDGCondition.m
//  GoldDigger
//
//  Created by Pietro Caselani on 2/8/16.
//

#import "GDGCondition.h"

#import "GDGColumn.h"
#import "GDGQuery.h"
#import "GDGTableSource.h"
#import <ObjectiveSugar/ObjectiveSugar.h>

#import <objc/runtime.h>

@interface GDGCondition ()

@property (strong, nonatomic) id context;
@property (strong, nonatomic) NSMutableArray<NSString *> *strings;
@property (strong, nonatomic) NSMutableDictionary<NSString *, id> *args;

@end

@implementation GDGCondition

+ (instancetype)builder
{
	return [[GDGCondition alloc] init];
}

- (instancetype)init
{
	if (self = [super init])
	{
		_strings = [[NSMutableArray alloc] init];
		_args = [[NSMutableDictionary alloc] init];
		_context = nil;

		__weak typeof(self) weakSelf = self;

		_col = ^GDGCondition *(GDGColumn *column) {
			weakSelf.context = column;

			[weakSelf.strings addObject:column.fullName];
			return weakSelf;
		};

		_func = ^GDGCondition *(NSString *desc, NSArray<GDGColumn *> *params) {
			weakSelf.context = desc;

			[weakSelf.strings addObject:[NSString stringWithFormat:@"%@(%@)", desc, [[params map:^id(id object) {
				return [object fullName];
			}] join:@", "]]];

			return weakSelf;
		};

		_equals = ^GDGCondition *(id value) {
			return [weakSelf appendValue:value forOperator:@"="];
		};

		_gt = ^GDGCondition *(id value) {
			return [weakSelf appendValue:value forOperator:@">"];
		};

		_gte = ^GDGCondition *(id value) {
			return [weakSelf appendValue:value forOperator:@">="];
		};

		_lt = ^GDGCondition *(id value) {
			return [weakSelf appendValue:value forOperator:@"<"];
		};

		_lte = ^GDGCondition *(id value) {
			return [weakSelf appendValue:value forOperator:@"<="];
		};

		_notEquals = ^GDGCondition *(id value) {
			return [weakSelf appendValue:value forOperator:@"<>"];
		};

		_build = ^GDGCondition *(void (^builderHandler)(GDGCondition *)) {
			return [weakSelf build:builderHandler];
		};

		_isNull = ^GDGCondition * {
			return [weakSelf appendText:@"IS NULL"];
		};

		_isNotNull = ^GDGCondition * {
			return [weakSelf appendText:@"IS NOT NULL"];
		};

		_equalsCol = ^GDGCondition *(GDGColumn *column) {
			[weakSelf appendValue:column.fullName forOperator:@"="];
			return weakSelf;
		};

		_inText = ^GDGCondition *(NSString *text) {
			return [weakSelf appendText:[NSString stringWithFormat:@"IN (%@)", text]];
		};

		_inList = ^GDGCondition *(NSArray<NSNumber *> *array) {
			NSString *arrayString = [[array map:^id(id object) {
				return [NSString stringWithFormat:@"%d", [object intValue]];
			}] join:@", "];

			return weakSelf.inText(arrayString);
		};

		_cat = ^GDGCondition *(GDGCondition *builder) {
			[weakSelf.args addEntriesFromDictionary:builder.args];
			return [[weakSelf and] appendText:builder.visit];
		};

		_inQuery = ^GDGCondition *(GDGQuery *query) {
			NSDictionary<NSString *, id> *arguments = query.arguments;
			NSString *sql = query.visit;

			NSMutableDictionary<NSString *, id> *newArguments = [[NSMutableDictionary alloc] initWithCapacity:arguments.count];

			for (NSString *key in arguments.allKeys)
			{
				if ([weakSelf.args hasKey:key])
				{
					unsigned int random = arc4random() % 100;
					NSString *argumentName = [NSString stringWithFormat:@"%@%u", key, random];

					newArguments[argumentName] = arguments[key];

					sql = [sql stringByReplacingOccurrencesOfString:key withString:argumentName];
				}
				else
					newArguments[key] = arguments[key];
			}

			[weakSelf.args addEntriesFromDictionary:newArguments];

			return weakSelf.inText(sql);
		};

		_DATE = ^GDGCondition *(GDGColumn *arg) {
			return weakSelf.func(@"DATE", @[arg]);
		};
	}

	return self;
}

- (GDGCondition *)build:(void (^)(GDGCondition *))builder
{
	[self appendText:@"("];
	builder(self);
	[self appendText:@")"];
	return self;
}

- (GDGCondition *)and
{
	return [self appendText:@"AND"];
}

- (GDGCondition *)or
{
	return [self appendText:@"OR"];
}

- (GDGCondition *)openParentheses
{
	return [self appendText:@"("];
}

- (GDGCondition *)closeParentheses
{
	return [self appendText:@")"];
}

- (GDGCondition *)appendValue:(id)value forOperator:(NSString *)operator
{
	if (!_context)
		@throw [NSException exceptionWithName:@"Non Existent Context"
		                               reason:@"[GDGCondition -appendValue:forOperator:] throws that you must provide a context before using an operator"
		                             userInfo:nil];

	NSString *context = [_context isKindOfClass:[GDGColumn class]] ? [_context name] : _context;
	NSString *name = [NSString stringWithFormat:@"%@%u", context, arc4random() % 100];

	[self appendText:operator];
	[self appendText:[NSString stringWithFormat:@":%@", name]];

	_args[name] = value;

	return self;
}

- (GDGCondition *)appendText:(NSString *)text
{
	[_strings addObject:[NSString stringWithFormat:@"%@", text]];

	return self;
}

- (NSDictionary<NSString *, id> *)arguments
{
	return [NSDictionary dictionaryWithDictionary:_args];
}

- (NSString *)visit
{
	return [_strings join:@" "];
}

- (BOOL)isEmpty
{
	return _strings.count == 0;
}

- (GDGCondition *)copyWithZone:(nullable NSZone *)zone
{
	GDGCondition *copy = (GDGCondition *) [[[self class] allocWithZone:zone] init];

	copy.strings = [_strings mutableCopy];
	copy.args = [_args mutableCopy];
	copy.context = [_context copy];

	return copy;
}

@end
