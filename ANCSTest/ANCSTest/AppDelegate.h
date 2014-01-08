//
//  AppDelegate.h
//  ANCSTest
//
//  Created by Khaos Tian on 7/9/13.
//  Copyright (c) 2013 Oltica. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <IOBluetooth/IOBluetooth.h>

@interface AppDelegate : NSObject <NSApplicationDelegate,CBCentralManagerDelegate,CBPeripheralDelegate,NSUserNotificationCenterDelegate>

@property (assign) IBOutlet NSWindow *window;
- (IBAction)sendMessage:(id)sender;

@end
