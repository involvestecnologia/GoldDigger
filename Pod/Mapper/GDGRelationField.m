//
// Created by Felipe Lobo on 2018-12-29.
//

#import "GDGCondition.h"
#import "GDGRelationField.h"
#import "GDGSource.h"


@implementation GDGRelationField

+ (instancetype)relationFieldWithName:(NSString *)name
                               source:(id <GDGSource>)source
{
	GDGRelationField *conditionField = [[GDGRelationField alloc] init];
	conditionField->_name = name;
	conditionField->_source = source;

	return conditionField;
}

- (NSString *)fullName
{
	return [NSString stringWithFormat:@"%@.%@", _source.identifier, _name];
}

@end