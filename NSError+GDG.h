//
// Created by Felipe Lobo on 2018-11-02.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT typedef NSInteger GDGErrorCode;

FOUNDATION_EXPORT const GDGErrorCode GDGParseUnknownArgumentKindError = 100;
FOUNDATION_EXPORT const GDGErrorCode GDGParseArgumentConditionError = 101;
FOUNDATION_EXPORT const GDGErrorCode GDGParseQuerySourceError = 200;
FOUNDATION_EXPORT const GDGErrorCode GDGParseJoinConditionError = 201;
FOUNDATION_EXPORT const GDGErrorCode GDGParseWhereConditionError = 202;
FOUNDATION_EXPORT const GDGErrorCode GDGParseHavingConditionError = 203;
FOUNDATION_EXPORT const GDGErrorCode GDGResultIterationError = 500;
FOUNDATION_EXPORT const GDGErrorCode GDGConnectionInsertError = 510;
FOUNDATION_EXPORT const GDGErrorCode GDGConnectionUpdateError = 511;
FOUNDATION_EXPORT const GDGErrorCode GDGConnectionDeleteError = 512;
FOUNDATION_EXPORT const GDGErrorCode GDGConnectionPrepareInsertError = 520;
FOUNDATION_EXPORT const GDGErrorCode GDGConnectionPrepareUpdateError = 521;
FOUNDATION_EXPORT const GDGErrorCode GDGConnectionPrepareDeleteError = 522;
FOUNDATION_EXPORT const GDGErrorCode GDGConnectionQueryEvaluationError = 530;
FOUNDATION_EXPORT const GDGErrorCode GDGQueryDuplicateJoinError = 800;
FOUNDATION_EXPORT const GDGErrorCode GDGConnectionPragmaTableInfoError = 900;
FOUNDATION_EXPORT const GDGErrorCode GDGConnectionColumnIterationError = 901;

FOUNDATION_EXPORT NSErrorDomain const GDGErrorDomain;

@interface NSError (GDG)

+ (instancetype)errorWithCode:(GDGErrorCode)code
                      message:(NSString *__nonnull)message
                   underlying:(NSError *__nullable)error;

@end