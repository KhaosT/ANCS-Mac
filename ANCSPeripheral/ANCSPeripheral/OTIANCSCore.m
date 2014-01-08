//
//  OTIANCSCore.m
//  ANCSPeripheral
//
//  Created by Khaos Tian on 12/30/13.
//  Copyright (c) 2013 Oltica. All rights reserved.
//

#import "OTIANCSCore.h"

@interface OTIANCSCore ()<CBPeripheralManagerDelegate>
{
    CBPeripheralManager     *_manager;
    
    CBMutableService        *_service;
    CBMutableCharacteristic *_controlChar;
}

@end

@implementation OTIANCSCore

- (void)setupANCS
{
    _manager = [[CBPeripheralManager alloc]initWithDelegate:self queue:dispatch_queue_create("org.oltica.ancs.peripheral", DISPATCH_QUEUE_SERIAL) options:@{CBPeripheralManagerOptionRestoreIdentifierKey: @"org.oltica.ancs.peripheral"}];
}

- (void)prepareService
{
    _controlChar = [[CBMutableCharacteristic alloc]initWithType:[CBUUID UUIDWithString:@"629B4394-7040-49C5-B0D0-218AB5FC92CD"] properties:(CBCharacteristicPropertyRead|CBCharacteristicPropertyWrite|CBCharacteristicPropertyNotifyEncryptionRequired) value:nil permissions:(CBAttributePermissionsReadEncryptionRequired|CBAttributePermissionsWriteEncryptionRequired)];
    _service = [[CBMutableService alloc]initWithType:[CBUUID UUIDWithString:@"C70CB8F3-BB87-4412-B2D4-A90702ABDA0F"] primary:YES];
    _service.characteristics = @[_controlChar];
    [_manager addService:_service];
}

- (void)startAdv
{
    NSDictionary *advData = @{CBAdvertisementDataServiceUUIDsKey: @[[CBUUID UUIDWithString:@"C70CB8F3-BB87-4412-B2D4-A90702ABDA0F"]]};
    [_manager startAdvertising:advData];
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral willRestoreState:(NSDictionary *)dict
{
    NSLog(@"RestoreWithDict:%@",dict);
}

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    if (peripheral.state == CBPeripheralManagerStatePoweredOn) {
        [self prepareService];
    }
}

- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error
{
    if (!error) {
        NSLog(@"StartAdv");
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error
{
    if (!error) {
        [self startAdv];
    }
}

@end
