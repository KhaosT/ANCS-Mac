//
//  AppDelegate.m
//  ANCSTest
//
//  Created by Khaos Tian on 7/9/13.
//  Copyright (c) 2013 Oltica. All rights reserved.
//

#import "AppDelegate.h"
#import "Define.h"
#import "NCDataObject.h"

@implementation AppDelegate{
    CBCentralManager    *_manager;
    CBPeripheral        *_np;
    
    CBCharacteristic    *_ds;
    CBCharacteristic    *_cp;
    CBCharacteristic    *_ns;
    
    NSMutableData       *_dsDataCache;
    
    CBCharacteristic    *_controlChar;
    
    NSTimer             *_delayTimer;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    _manager = [[CBCentralManager alloc]initWithDelegate:self queue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    [NSUserNotificationCenter defaultUserNotificationCenter].delegate = self;
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
    [_manager cancelPeripheralConnection:_np];
}

- (void)startScan{
    NSLog(@"Start Scan");
    [_manager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:@"C70CB8F3-BB87-4412-B2D4-A90702ABDA0F"]] options:@{ CBCentralManagerScanOptionAllowDuplicatesKey : [NSNumber numberWithBool:YES] }];
}

- (NSData *)buildCommandForGettingNotificationWithUID:(NSData *)uidData Attributes:(NSArray *)reqAttr
{
    NSMutableData *data = [[NSMutableData alloc]initWithBytes:"\x00" length:1];
    [data appendData:uidData];
    for (NSDictionary *dict in reqAttr) {
        [data appendData:[dict objectForKey:@"action"]];
        if ([dict objectForKey:@"length"]) {
            [data appendData:[dict objectForKey:@"length"]];
        }
    }
    NSLog(@"%@",data);
    return data;
}

- (void)processNotificationUpdateData:(NSData *)data
{
    NSUInteger len = [data length];
    Byte *byteData = (Byte*)malloc(len);
    memcpy(byteData, [data bytes], len);
    switch (byteData[0]) {
        case EventIDNotificationAdded:
        {
            NSLog(@"Event Added");
            NSArray *cmdArray = @[@{@"action": [NSData dataWithBytes:"\x00" length:1]},
                                  @{@"action": [NSData dataWithBytes:"\x01" length:1],@"length":[NSData dataWithBytes:"\xFF\xFF" length:2]},
                                  @{@"action": [NSData dataWithBytes:"\x02" length:1],@"length":[NSData dataWithBytes:"\xFF\xFF" length:2]},
                                  @{@"action": [NSData dataWithBytes:"\x03" length:1],@"length":[NSData dataWithBytes:"\xFF\xFF" length:2]}];
            
            [_np writeValue:[self buildCommandForGettingNotificationWithUID:[data subdataWithRange:NSMakeRange(4, 4)] Attributes:cmdArray] forCharacteristic:_cp type:CBCharacteristicWriteWithResponse];
        }
            break;
        
        case EventIDNotificationModified:
            NSLog(@"Event Modified");
            break;
            
        case EventIDNotificationRemoved:
            NSLog(@"Event Removed");
            break;
            
        default:
            NSLog(@"Unknown Event:%i",byteData[0]);
            break;
    }
}

- (void)processDataSource:(NSData *)data
{
    if (![[data subdataWithRange:NSMakeRange(0, 1)]isEqualToData:[NSData dataWithBytes:"\x00" length:1]] && _dsDataCache) {
        [_dsDataCache appendData:data];
    }else{
        _dsDataCache = [data mutableCopy];
    }
    if (data.length == 20) {
        if (_delayTimer) {
            [_delayTimer invalidate];
            _delayTimer = nil;
        }
        _delayTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(finalizeDataSourceReply) userInfo:nil repeats:NO];
    }else{
        [self finalizeDataSourceReply];
    }
    
}

- (void)finalizeDataSourceReply
{
    if (_delayTimer) {
        [_delayTimer invalidate];
        _delayTimer = nil;
    }
    NSLog(@"%@",_dsDataCache);
    
    NSData *uid = [_dsDataCache subdataWithRange:NSMakeRange(1, 4)];
    NSData *messageData = [_dsDataCache subdataWithRange:NSMakeRange(5, [_dsDataCache length]-5)];
    NSInteger currentIndex = 0;
    NSUInteger len = [messageData length];
    Byte *byteData = (Byte*)malloc(len);
    memcpy(byteData, [messageData bytes], len);
    NSMutableDictionary *dict = [[NSMutableDictionary alloc]init];
    while (currentIndex < messageData.length) {
        int messageLength = byteData[currentIndex+1];
        NCDataObject *dataObject = [[NCDataObject alloc]initWithUID:uid Type:byteData[currentIndex+0] data:[messageData subdataWithRange:NSMakeRange(currentIndex+3, messageLength)]];
        NSLog(@"%@",[dataObject description]);
        if (dataObject.type == 1) {
            [dict setObject:dataObject forKey:@"app"];
        }
        if (dataObject.type == 3) {
            [dict setObject:dataObject forKey:@"message"];
        }
        currentIndex = currentIndex + 3 + messageLength;
    }
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    notification.title = [(NCDataObject *)[dict objectForKey:@"app"] data];
    notification.informativeText = [(NCDataObject *)[dict objectForKey:@"message"] data];
    notification.soundName = NSUserNotificationDefaultSoundName;
    //notification.hasActionButton = YES;
    //notification.hasReplyButton = YES;
    
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification
{
    if (notification.activationType == NSUserNotificationActivationTypeReplied){
        NSString* userResponse = notification.response.string;
        NSLog(@"Res:%@",userResponse);
    }
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central{
    if (central.state == CBCentralManagerStatePoweredOn) {
        [self startScan];
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI{
    NSLog(@"Advert:%@",advertisementData.description);
    _np = peripheral;

    [central connectPeripheral:peripheral options:nil];
    [central stopScan];
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    [peripheral setDelegate:self];
    [peripheral discoverServices:nil];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    if (error) {
        NSLog(@"%@",error);
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    for (CBService *aService in peripheral.services){
        
        if ([aService.UUID isEqual:[CBUUID UUIDWithString:@"C70CB8F3-BB87-4412-B2D4-A90702ABDA0F"]]) {
            NSLog(@"Found Control");
            [peripheral discoverCharacteristics:nil forService:aService];
        }
        if ([aService.UUID isEqual:[CBUUID UUIDWithString:ANCS_SERVICE]]) {
            [peripheral discoverCharacteristics:nil forService:aService];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    for (CBCharacteristic *aChar in service.characteristics){
        NSLog(@"Char:%@",aChar.UUID);
        /*if ([aChar.UUID isEqual:[CBUUID UUIDWithString:@"DA18"]]) {
            NSLog(@"Discover Notification Source");
            NSLog(@"%ld",aChar.properties);
            _ns = aChar;
            //[peripheral setNotifyValue:YES forCharacteristic:aChar];
        }
        if ([aChar.UUID isEqual:[CBUUID UUIDWithString:@"DA17"]]) {
            NSLog(@"Discover Control Point");
            NSLog(@"%ld",aChar.properties);
            
            _cp = aChar;
        }*/
        if ([aChar.UUID isEqual:[CBUUID UUIDWithString:@"629B4394-7040-49C5-B0D0-218AB5FC92CD"]]) {
            NSLog(@"Discover SELF Control");
            _controlChar = aChar;
            [peripheral setNotifyValue:YES forCharacteristic:aChar];
            [peripheral readValueForCharacteristic:aChar];
        }
        if ([aChar.UUID isEqual:[CBUUID UUIDWithString:NOTIFICATION_SOURCE]]) {
            NSLog(@"Discover Notification Source");
            _ns = aChar;
            [peripheral setNotifyValue:YES forCharacteristic:aChar];
        }
        if ([aChar.UUID isEqual:[CBUUID UUIDWithString:DATA_SOURCE]]) {
            NSLog(@"Discover Data Source");
            _ds = aChar;
            [peripheral setNotifyValue:YES forCharacteristic:aChar];
        }
        if ([aChar.UUID isEqual:[CBUUID UUIDWithString:CONTROL_POINT]]) {
            NSLog(@"Discover Control Point");
            
            _cp = aChar;
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    if (error) {
        NSLog(@"%@",[error description]);
    }
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:NOTIFICATION_SOURCE]]) {
        NSLog(@"Notification:%@",characteristic.value.description);

        [self processNotificationUpdateData:characteristic.value];
    }
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:DATA_SOURCE]]) {
        NSLog(@"Data Source:%@",characteristic.value.description);

        [self processDataSource:characteristic.value];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSLog(@"Write");
    if (error) {
        NSLog(@"Error:%@",error);
    }
}


- (IBAction)sendMessage:(id)sender {
    //[_np writeValue:[NSData dataWithBytes:"\x12" length:1] forCharacteristic:_cp type:CBCharacteristicWriteWithResponse];
}

@end
