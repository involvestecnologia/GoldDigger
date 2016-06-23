//
//  GDGCondition.m
//  GoldDigger
//
//  Created by Pietro Caselani on 2/8/16.
//

#import <objc/runtime.h>
#import <ObjectiveSugar/ObjectiveSugar.h>
#import "GDGCondition.h"
#import "GDGCondition_Protected.h"

@implementation GDGCondition

+ (instancetype)builder
{
	return [[GDGCondition alloc] init];
}

#pragma mark - Initialization

- (instancetype)init
{
	if (self = [super init])
	{
		_mutableTokens = [NSMutableArray array];
		_mutableFields = [NSMutableDictionary dictionary];
		_mutableArgs = [NSMutableDictionary dictionary];
		_context = nil;

		__weak typeof(self) weakSelf = self;

		_field = ^GDGCondition *(id <GDGConditionField> field) {
			[weakSelf appendField:field];

			weakSelf.context = field.fullName;

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

		_in = ^GDGCondition *(id arg) {
			return [weakSelf appendValue:arg forOperator:@"IN"];
		};

		_cat = ^GDGCondition *(GDGCondition *builder) {
			[weakSelf.mutableArgs addEntriesFromDictionary:builder.mutableArgs];
			[weakSelf.mutableTokens addObjectsFromArray:builder->_mutableTokens];
			return weakSelf;
		};
	}

	return self;
}

#pragma mark - Build

- (GDGCondition *)build:(void (^)(GDGCondition *))builder
{
	[_mutableTokens addObject:@"("];
	builder(self);
	[_mutableTokens addObject:@")"];
	return self;
}

- (GDGCondition *)and
{
	[_mutableTokens addObject:@"AND"];
	return self;
}

- (GDGCondition *)or
{
	[_mutableTokens addObject:@"OR"];
	return self;
}

- (GDGCondition *)null
{
	[_mutableTokens addObject:@"NULL"];
	return self;
}

- (GDGCondition *)notNull
{
	[_mutableTokens addObject:@"NOTNULL"];
	return self;
}

- (GDGCondition *)appendValue:(id)value forOperator:(NSString *)operator
{
	if (!_context)
		@throw [NSException exceptionWithName:@"Non Existent Context"
		                               reason:@"[GDGCondition -appendValue:forOperator:] throws that you must provide a context before using an operator"
		                             userInfo:nil];

	[_mutableTokens addObject:operator];

	if ([value conformsToProtocol:@protocol(GDGConditionField)])
		[self appendField:value];
	else
	{
		NSString *argName = NSStringWithFormat(@"ARG_%u", _mutableArgs.count);

		_mutableArgs[argName] = value;

		[_mutableTokens addObject:argName];
	}

	return self;
}

- (BOOL)isEmpty
{
	return _mutableTokens.count == 0;
}

#pragma mark - Private impl

- (void)appendField:(id <GDGConditionField>)field
{
	NSString *fieldName = field.fullName;
	NSString *token = NSStringWithFormat(@"FIELD_%@", fieldName);

	_mutableFields[token] = field;

	[_mutableTokens addObject:token];
}

#pragma mark - Computed

- (NSArray *)tokens
{
	return [NSArray arrayWithArray:_mutableTokens];
}

- (NSDictionary *)fields
{
	return [NSMutableDictionary dictionaryWithDictionary:_mutableFields];
}

- (NSDictionary *)args
{
	return [NSMutableDictionary dictionaryWithDictionary:_mutableArgs];
}

#pragma mark - Copying

- (GDGCondition *)copyWithZone:(nullable NSZone *)zone
{
	GDGCondition *copy = (GDGCondition *) [[[self class] allocWithZone:zone] init];

	copy->_mutableTokens = [_mutableTokens mutableCopy];
	copy->_mutableArgs = [_mutableArgs mutableCopy];
	copy->_mutableFields = [_mutableFields mutableCopy];
	copy->_context = [_context copy];

	return copy;
}

@end
