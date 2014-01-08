//
//  NCDataObject.m
//  ANCSTest
//
//  Created by Khaos Tian on 12/30/13.
//  Copyright (c) 2013 Oltica. All rights reserved.
//

#import "NCDataObject.h"

@implementation NCDataObject

- (id)initWithUID:(NSData *)uid Type:(NSInteger)typeID data:(NSData *)message
{
    if (self = [super init]) {
        _uid = [uid copy];
        _type = typeID;
        _data = [[NSString alloc]initWithData:message encoding:NSUTF8StringEncoding];
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"UID:%@, Type:%li, Message:%@",_uid,_type,_data];
}

@end
