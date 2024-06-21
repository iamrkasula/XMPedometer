//
//  BIMPedometerManager.m
//  StepDemo
//
//  Created by 刘灿 on 2019/4/30.
//  Copyright © 2019 Epoint. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>
#import "XMPedometerManager.h"
#define kCustomErrorDomain @"com.github.ixmwl"

kPedometerIdentier const kPedometerIdentifierIndex = @"kPedometerIdentifierIndex";
kPedometerIdentier const kPedometerIdentifierDate = @"kPedometerIdentifierDate";
kPedometerIdentier const kPedometerIdentifierNumberOfSteps = @"kPedometerIdentifierNumberOfSteps";
kPedometerIdentier const kPedometerIdentifierDistance = @"kPedometerIdentifierDistance";
kPedometerIdentier const kPedometerIdentifierFloorsAscended = @"kPedometerIdentifierFloorsAscended";
kPedometerIdentier const kPedometerIdentifierFloorsDescended = @"kPedometerIdentifierFloorsDescended";
kPedometerIdentier const kPedometerIdentifierCurrentPace = @"kPedometerIdentifierCurrentPace";
kPedometerIdentier const kPedometerIdentifierCurrentCadence = @"kPedometerIdentifierCurrentCadence";
kPedometerIdentier const kPedometerIdentifierAverageActivePace = @"kPedometerIdentifierAverageActivePace";


#pragma mark - 计步管理工具类
@interface XMPedometerManager ()

@property (nonatomic, strong) CMPedometer *pedometer;

@end

@implementation XMPedometerManager

static XMPedometerManager *instance = nil;

+ (instancetype)sharedManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[XMPedometerManager alloc] init];
    });
    return instance;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    if (!instance) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            instance = [super allocWithZone:zone];
        });
    }
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        if ([CMPedometer isStepCountingAvailable]) {
            self.pedometer = [[CMPedometer alloc] init];
        }
    }
    return self;
}


- (void)xm_startPedometerUpdatesFromTodayWithHandler:(XMPedometerCompletionBlock)handler {
    [self xm_startPedometerUpdatesFromDate:[NSDate getTodayStartDate] withHandler:handler];
}

- (void)xm_startPedometerUpdatesFromDate:(NSDate *)fromDate withHandler:(XMPedometerCompletionBlock)handler {
    if (!self.pedometer) {
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey : @"device does not support"};
        NSError *error = [[NSError alloc] initWithDomain:kCustomErrorDomain code:-666 userInfo:userInfo];
        handler(nil, nil, nil, nil, nil, nil, nil, error);
        return;
    }
    [self.pedometer startPedometerUpdatesFromDate:fromDate withHandler:^(CMPedometerData * _Nullable pedometerData, NSError * _Nullable error) {
        if (handler) {
            if (error) {
                handler(nil, nil, nil, nil, nil, nil, nil, error);
            } else {
                if (@available(iOS 10.0, *)) {
                    handler(pedometerData.numberOfSteps,
                            pedometerData.distance,
                            pedometerData.floorsAscended,
                            pedometerData.floorsDescended,
                            pedometerData.currentPace,
                            pedometerData.currentCadence,
                            pedometerData.averageActivePace,
                            nil);
                } else {
                    // Fallback on earlier versions
                }
            }
        }
    }];
}

- (void)xm_queryPedometerDataForTheLatestSevenDaysWithHandler:(void(^)(NSArray<NSDictionary *> * infoArr, NSError *error))handler {
    [self xm_queryPedometerDataBeforeTodayWithIndex:7 withHandler:handler];
}

- (void)xm_queryPedometerDataBeforeTodayWithIndex:(NSInteger)index withHandler:(void (^)(NSArray<NSDictionary *> *infoArr, NSError *error))handler {
    if (index <= 0) {
        return;
    }
    NSMutableArray *arr = [NSMutableArray array];
    
    for (int i = 0; i < index; i++) {
        if (i == 0) {
            [self xm_queryPedometerDataFromDate:[NSDate getTodayStartDate] toDate:[NSDate date] withHandler:^(NSNumber *numberOfSteps, NSNumber *distance, NSNumber *floorsAscended, NSNumber *floorsDescended, NSNumber *currentPace, NSNumber *currentCadence, NSNumber *averageActivePace, NSError *error) {
                if (error) {
                    if (handler) {
                        handler(nil, error);
                    }
                } else {
            
                    NSMutableDictionary *infoDict = [[NSMutableDictionary alloc] initWithDictionary:@{kPedometerIdentifierIndex : @(i),
                                                                                                      kPedometerIdentifierDate : [NSDate nowDateAtZoneWithDate:[NSDate getTodayStartDate]]}];
                    if(numberOfSteps) {
                        [infoDict setValue:numberOfSteps forKey:kPedometerIdentifierNumberOfSteps];
                    }
                    if(distance) {
                        [infoDict setValue:distance forKey:kPedometerIdentifierDistance];
                    }
                    if(floorsAscended) {
                        [infoDict setValue:floorsAscended forKey:kPedometerIdentifierFloorsAscended];
                    }
                    if(floorsDescended) {
                        [infoDict setValue:floorsDescended forKey:kPedometerIdentifierFloorsDescended];
                    }
                    if(currentPace) {
                        [infoDict setValue:currentPace forKey:kPedometerIdentifierCurrentPace];
                    }
                    if(currentCadence) {
                        [infoDict setValue:currentCadence forKey:kPedometerIdentifierCurrentCadence];
                    }
                    if(averageActivePace) {
                        [infoDict setValue:averageActivePace forKey:kPedometerIdentifierAverageActivePace];
                    }
                    [arr addObject:[infoDict copy]];
                }
            }];
            
        } else {
            [self xm_queryPedometerDataFromDate:[NSDate getDateBeforeTodayAtIndex:i] toDate:[NSDate getDateBeforeTodayAtIndex:i-1] withHandler:^(NSNumber *numberOfSteps, NSNumber *distance, NSNumber *floorsAscended, NSNumber *floorsDescended, NSNumber *currentPace, NSNumber *currentCadence, NSNumber *averageActivePace, NSError *error) {
                if (error) {
                    if (handler) {
                        handler(nil, error);
                    }
                } else {
                    NSMutableDictionary *infoDict = [[NSMutableDictionary alloc] initWithDictionary:@{kPedometerIdentifierIndex : @(i),
                                                                                                      kPedometerIdentifierDate : [NSDate nowDateAtZoneWithDate:[NSDate getDateBeforeTodayAtIndex:i]]}];
                    if(numberOfSteps) {
                        [infoDict setValue:numberOfSteps forKey:kPedometerIdentifierNumberOfSteps];
                    }
                    if(distance) {
                        [infoDict setValue:distance forKey:kPedometerIdentifierDistance];
                    }
                    if(floorsAscended) {
                        [infoDict setValue:floorsAscended forKey:kPedometerIdentifierFloorsAscended];
                    }
                    if(floorsDescended) {
                        [infoDict setValue:floorsDescended forKey:kPedometerIdentifierFloorsDescended];
                    }
                    if(currentPace) {
                        [infoDict setValue:currentPace forKey:kPedometerIdentifierCurrentPace];
                    }
                    if(currentCadence) {
                        [infoDict setValue:currentCadence forKey:kPedometerIdentifierCurrentCadence];
                    }
                    if(averageActivePace) {
                        [infoDict setValue:averageActivePace forKey:kPedometerIdentifierAverageActivePace];
                    }
                    [arr addObject:[infoDict copy]];
                }
                if (arr.count == index) {
                    if (handler) {
                        handler(arr, nil);
                    }
                }
            }];
        }
    }
    
}

- (void)xm_queryPedometerDataFromDate:(NSDate *)start toDate:(NSDate *)end withHandler:(XMPedometerCompletionBlock)handler {
    if (!self.pedometer) {
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey : @"device does not support"};
        NSError *error = [[NSError alloc] initWithDomain:kCustomErrorDomain code:-666 userInfo:userInfo];
        handler(nil, nil, nil, nil, nil, nil, nil, error);
        return;
    }
    [self.pedometer queryPedometerDataFromDate:start toDate:end withHandler:^(CMPedometerData * _Nullable pedometerData, NSError * _Nullable error) {
        if (handler) {
            if (error) {
                handler(nil, nil, nil, nil, nil, nil, nil, error);
            } else {
                if (@available(iOS 9.0, *)) {
                    if (@available(iOS 10.0, *)) {
                        handler(pedometerData.numberOfSteps,
                                pedometerData.distance,
                                pedometerData.floorsAscended,
                                pedometerData.floorsDescended,
                                pedometerData.currentPace,
                                pedometerData.currentCadence,
                                pedometerData.averageActivePace,
                                nil);
                    } else {
                        // Fallback on earlier versions
                    }
                } else {
                    // Fallback on earlier versions
                }
            }
        }
    }];
}


@end


#pragma mark - 时间管理工具
@implementation NSDate (BIMTool)
/// 获取今天凌晨0点时间
+ (NSDate *)getTodayStartDate {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd";
    NSString *dateStr = [dateFormatter stringFromDate:[NSDate date]];
    NSDate *tDate = [dateFormatter dateFromString:dateStr];
    return tDate;
}

/// 获取距离前几天的凌晨0点时间
+ (NSDate *)getDateBeforeTodayAtIndex:(NSInteger)index {
    return [[NSDate alloc] initWithTimeInterval:(-60 * 60 * 24 * index) sinceDate:[self getTodayStartDate]];
}

/// 去除时差
+ (NSDate *)nowDateAtZoneWithDate:(NSDate *)date {
    NSTimeZone *zone = [NSTimeZone systemTimeZone];
    NSInteger interval = [zone secondsFromGMTForDate:date];
    return [date dateByAddingTimeInterval:interval];
}
@end
