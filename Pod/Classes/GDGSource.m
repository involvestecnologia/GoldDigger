//
//  GDGSource.m
//  Pods
//
//  Created by Pietro Caselani on 2/12/16.
//
//

#import "GDGSource.h"

#import "ObjectiveSugar.h"

@implementation GDGSource

- (void)setColumns:(NSArray<GDGColumn *> *)columns
{
	for (GDGColumn *column in columns)
		column.source = self;
	
	_columns = columns;
}

- (GDGColumn*)columnNamed:(NSString*)columnName
{
	columnName = [self adjustColumnNamed:columnName];
	
	NSInteger dotIndex = [columnName rangeOfString:@"."].location;
	
	NSString *sourceName = [columnName substringToIndex:dotIndex];
	NSString *columnRealName = [columnName substringFromIndex:dotIndex + 1];
	
	return [self.alias caseInsensitiveCompare:sourceName] == NSOrderedSame ? [self.columns detect:^BOOL(id object) {
		return [((GDGColumn*) object).name caseInsensitiveCompare:columnRealName] == NSOrderedSame;
	}] : nil;
}

- (NSString*)adjustColumnNamed:(NSString*)columnName
{
	NSInteger dotIndex = [columnName rangeOfString:@"."].location;
	return dotIndex != NSNotFound ? columnName : [_alias stringByAppendingFormat:@".%@", columnName];
}

- (GDGColumn*)objectForKeyedSubscript:(NSString*)idx
{
	return [self columnNamed:idx];
}

- (void)setObject:(id)obj forKeyedSubscript:(NSString*)idx
{
	@throw [NSException exceptionWithName:@"Unsupported exception" reason:@"Can't set a column object" userInfo:nil];
}

@end
