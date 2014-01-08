//
//  NCDataObject.h
//  ANCSTest
//
//  Created by Khaos Tian on 12/30/13.
//  Copyright (c) 2013 Oltica. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NCDataObject : NSObject

@property   (nonatomic,strong) NSData *uid;
@property   (nonatomic,readwrite) NSInteger type;
@property   (nonatomic,strong) NSString *data;

- (id)initWithUID:(NSData *)uid Type:(NSInteger)typeID data:(NSData *)message;

@end
