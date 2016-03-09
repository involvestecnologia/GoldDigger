//
//  GDGConditionBuilder.m
//  GoldDigger
//
//  Created by Pietro Caselani on 2/8/16.
//

#import "GDGConditionBuilder.h"

#import "GDGColumn.h"
#import "GDGQuery.h"
#import "GDGTableSource.h"
#import <ObjectiveSugar/ObjectiveSugar.h>

@interface GDGConditionBuilder ()

@property (strong, nonatomic) id context;
@property (strong, nonatomic) NSMutableArray<NSString *> *strings;
@property (strong, nonatomic) NSMutableDictionary<NSString *, id> *args;

@end

@implementation GDGConditionBuilder

+ (instancetype)builder
{
	return [[GDGConditionBuilder alloc] init];
}

- (instancetype)init
{
	if (self = [super init])
	{
		_strings = [[NSMutableArray alloc] init];
		_args = [[NSMutableDictionary alloc] init];
		_context = nil;

		__weak typeof(self) weakSelf = self;

		_col = ^GDGConditionBuilder *(GDGColumn *column) {
			weakSelf.context = column;

			[weakSelf.strings addObject:column.fullName];
			return weakSelf;
		};

		_func = ^GDGConditionBuilder *(NSString *desc, NSArray<GDGColumn *> *params) {
			weakSelf.context = desc;

			[weakSelf.strings addObject:[NSString stringWithFormat:@"%@(%@)", desc, [[params map:^id(id object) {
				return [object fullName];
			}] join:@", "]]];

			return weakSelf;
		};

		_equals = ^GDGConditionBuilder *(id value) {
			return [weakSelf appendValue:value forOperator:@"="];
		};

		_gt = ^GDGConditionBuilder *(id value) {
			return [weakSelf appendValue:value forOperator:@">"];
		};

		_gte = ^GDGConditionBuilder *(id value) {
			return [weakSelf appendValue:value forOperator:@">="];
		};

		_lt = ^GDGConditionBuilder *(id value) {
			return [weakSelf appendValue:value forOperator:@"<"];
		};

		_lte = ^GDGConditionBuilder *(id value) {
			return [weakSelf appendValue:value forOperator:@"<="];
		};

		_notEquals = ^GDGConditionBuilder *(id value) {
			return [weakSelf appendValue:value forOperator:@"<>"];
		};

		_build = ^GDGConditionBuilder *(void (^builderHandler)(GDGConditionBuilder *)) {
			return [weakSelf build:builderHandler];
		};

		_isNull = ^GDGConditionBuilder * {
			return [weakSelf appendText:@"IS NULL"];
		};

		_isNotNull = ^GDGConditionBuilder * {
			return [weakSelf appendText:@"IS NOT NULL"];
		};

		_equalsCol = ^GDGConditionBuilder *(GDGColumn *column) {
			[self appendValue:column.fullName forOperator:@"="];
			return weakSelf;
		};

		_inText = ^GDGConditionBuilder *(NSString *text) {
			return [weakSelf appendText:[NSString stringWithFormat:@"IN (%@)", text]];
		};

		_inList = ^GDGConditionBuilder *(NSArray<NSNumber *> *array) {
			NSString *arrayString = [[array map:^id(id object) {
				return [NSString stringWithFormat:@"%d", [object intValue]];
			}] join:@", "];

			return weakSelf.inText(arrayString);
		};

		_cat = ^GDGConditionBuilder *(GDGConditionBuilder *builder) {
			[weakSelf.args addEntriesFromDictionary:builder.args];
			return [[weakSelf and] appendText:builder.visit];
		};

		_inQuery = ^GDGConditionBuilder *(GDGQuery *query) {
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

		_DATE = ^GDGConditionBuilder *(GDGColumn *arg) {
			return weakSelf.func(@"DATE", @[arg]);
		};
	}

	return self;
}

- (GDGConditionBuilder *)build:(void (^)(GDGConditionBuilder *))builder
{
	[self appendText:@"("];
	builder(self);
	[self appendText:@")"];
	return self;
}

- (GDGConditionBuilder *)and
{
	return [self appendText:@"AND"];
}

- (GDGConditionBuilder *)or
{
	return [self appendText:@"OR"];
}

- (GDGConditionBuilder *)openParentheses
{
	return [self appendText:@"("];
}

- (GDGConditionBuilder *)closeParentheses
{
	return [self appendText:@")"];
}

- (GDGConditionBuilder *)appendValue:(id)value forOperator:(NSString *)operator
{
	if (!_context)
		@throw [NSException exceptionWithName:@"Non Existent Context"
		                               reason:@"[GDGConditionBuilder -appendValue:forOperator:] throws that you must provide a context before using an operator"
		                             userInfo:nil];

	NSString *context = [_context isKindOfClass:[GDGColumn class]] ? [_context name] : _context;
	NSString *name = [NSString stringWithFormat:@"%@%u", context, arc4random() % 100];

	[self appendText:operator];
	[self appendText:[NSString stringWithFormat:@":%@", name]];

	_args[name] = value;

	return self;
}

- (GDGConditionBuilder *)appendText:(NSString *)text
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

@end
