//
//  BluetoothComm.h
//  switch
//
//  Created by Ben Calder on 4/1/15.
//  Copyright (c) 2015 BTS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

#define SERVICE_UUID     0xFFE0
#define CHAR_UUID        0xFFE1

@protocol BTDelegate

@optional

- (void)peripheralFound:(CBPeripheral *)peripheral;
- (void)serialGATTCharValueUpdated:(NSString *)UUID value:(NSData *)data;
- (void)setConnect;
- (void)setDisconnect;
- (void)scanForPeripherals;

@end

@interface BluetoothComm : NSObject <CBCentralManagerDelegate, CBPeripheralDelegate> {
    
}

@property (nonatomic, assign) id <BTDelegate> delegate;

@property (strong, nonatomic) NSMutableArray *peripherals;

@property (strong, nonatomic) CBCentralManager *manager;

@property (strong, nonatomic) CBPeripheral *activePeripheral;

@property (strong, nonatomic) NSNumber *rssiN;


#pragma mark - Methods for controlling the HMSoft Sensor

- (void)setup; //controller setup
- (void)stopScan;

- (void)findPeripheralsWithTimeout:(int)timeout;
- (void)scanTimer:(NSTimer *)timer;

- (void)connect:(CBPeripheral *)peripheral;
- (void)disconnect:(CBPeripheral *)peripheral;

- (void)read:(CBPeripheral *)peripheral;
- (void)notify:(CBPeripheral *)peripheral on:(BOOL)on;

- (void)printPeripheralInfo:(CBPeripheral*)peripheral;

- (void)notification:(int)serviceUUID characteristicUUID:(int)characteristicUUID p:(CBPeripheral *)p on:(BOOL)on;
- (UInt16)swap:(UInt16)s;

- (CBService *)findServiceFromUUIDEx:(CBUUID *)UUID p:(CBPeripheral *)p;
- (CBCharacteristic *)findCharacteristicFromUUIDEx:(CBUUID *)UUID service:(CBService *)service;
- (void)readValue: (int)serviceUUID characteristicUUID:(int)characteristicUUID p:(CBPeripheral *)p;

@end
