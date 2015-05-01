//
//  BluetoothComm.m
//  switch
//
//  Created by Ben Calder on 4/1/15.
//  Copyright (c) 2015 BTS. All rights reserved.
//

#import "BluetoothComm.h"

@interface BluetoothComm ()

@property (strong, nonatomic) NSTimer *rssiT;

@end

@implementation BluetoothComm


- (void)setup   // enable CoreBluetooth CentralManager and set the delegate
{
 self.manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
}


- (void)findPeripheralsWithTimeout:(int)timeout
{
 if ([self.manager state] != CBCentralManagerStatePoweredOn)
    {
    NSLog(@"CoreBluetooth is not correctly initialized!");
    return;
    }
    
 [NSTimer scheduledTimerWithTimeInterval:(float)timeout target:self selector:@selector(scanTimer:) userInfo:nil repeats:NO];
 
 [self.manager scanForPeripheralsWithServices:[NSArray arrayWithObject:[CBUUID UUIDWithString:@"0xFFE0"]] options:0];
 
 return;
}


- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
 NSLog(@"Found peripheral with name: %@", peripheral.name);
 
 if (!self.peripherals)
    {
    self.peripherals = [[NSMutableArray alloc] initWithObjects:peripheral, nil];
    
    for (int i = 0; i < self.peripherals.count; i++)
        {
        [self.delegate peripheralFound:peripheral];
        }
    }
 
 if (peripheral.identifier.UUIDString == NULL) return;

 if (peripheral.name.length < 1) return;
        // Add the new peripheral to the peripherals array
 for (int i = 0; i < self.peripherals.count; i++)
     {
     CBPeripheral *p = [self.peripherals objectAtIndex:i];
     if (p.identifier.UUIDString == NULL) continue;
     CFUUIDBytes b1 = CFUUIDGetUUIDBytes((__bridge CFUUIDRef )p.identifier);
     CFUUIDBytes b2 = CFUUIDGetUUIDBytes((__bridge CFUUIDRef )peripheral.identifier);
     if (memcmp(&b1, &b2, 16) == 0)
        {
        // these are the same, and replace the old peripheral information
        [self.peripherals replaceObjectAtIndex:i withObject:peripheral];
        NSLog(@"Duplicated peripheral found");
        //[delegate peripheralFound: peripheral];
        return;
        }
      }
      
 NSLog(@"Peripheral added to array");
 [self.peripherals addObject:peripheral];
 [self.delegate peripheralFound:peripheral];
    
 return;
}


- (void)connect:(CBPeripheral *)peripheral   // connect to a given peripheral
{
 if (!(peripheral.state == CBPeripheralStateConnected)) [self.manager connectPeripheral:peripheral options:nil];
}


- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral   // callback after a connection has been made
{
 self.activePeripheral = peripheral;
 self.activePeripheral.delegate = self;
 
 [self printPeripheralInfo:peripheral];
 
 [self.activePeripheral discoverServices:nil];
 
 [self.delegate didConnect:peripheral];
    
 NSLog(@"Connected to the peripheral");
}


- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error   // called when CoreBluetooth has discovered services
{
 if (!error)
    {
    NSLog(@"Services found of peripheral with UUID : %@", peripheral.identifier.UUIDString);
    NSLog(@"Services are %@", peripheral.services);
    
    [self.delegate didDiscoverServices:peripheral];
    
    [peripheral discoverCharacteristics:nil forService:peripheral.services[0]];
    }
 else NSLog(@"Service discovery was unsuccessfull");
}


- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
 if (!error)
    {
    NSLog(@"Characteristics of service: %@", service.characteristics);
    
    for (CBCharacteristic *charac in service.characteristics)
       {
       NSLog(@"Descriptor of characteristic: %@", charac.descriptors);
       }
     
    for (int i = 0; i < service.characteristics.count; i++)
        { //Show every one
        CBCharacteristic *c = [service.characteristics objectAtIndex:i];
        NSLog(@"Found characteristic %@",c.UUID);
        }
        
    char t[16];
    t[0] = (SERVICE_UUID >> 8) & 0xFF;
    t[1] = SERVICE_UUID & 0xFF;
    NSData *data = [[NSData alloc] initWithBytes:t length:16];
    CBUUID *uuid = [CBUUID UUIDWithData:data];
    //CBService *s = [peripheral.services objectAtIndex:(peripheral.services.count - 1)];
    if ([self compareCBUUID:service.UUID UUID2:uuid])
       {
//       NSLog(@"Try to open notify");
//       [self notify:peripheral on:YES];
       }
    }
 else NSLog(@"Characteristic discovery unsuccessfull");
}


- (void)printPeripheralInfo:(CBPeripheral *)peripheral   // peripheral metadata
{
 NSLog(@"Peripheral UUID : %@", peripheral.identifier.UUIDString);
 NSLog(@"Name : %@", peripheral.name);
 NSLog(@"isConnected : %d", peripheral.state == CBPeripheralStateConnected);
 
 [peripheral readRSSI];
}


- (void)peripheral:(CBPeripheral *)peripheral didReadRSSI:(NSNumber *)RSSI error:(NSError *)error    // delegate callback from the readRSSI method
{
 self.rssiN = RSSI;
 NSLog(@"RSSI : %d",[RSSI intValue]);
}


- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
 if (!error) NSLog(@"Did write value for characteristic: %@", characteristic);
 else NSLog(@"Error: %@", error);
}


- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
 if (!error) NSLog(@"Updated value for characteristic: %@", characteristic);
 else NSLog(@"Error: %@", error);
}



/*!
 *  @method swap:
 *
 *  @param s Uint16 value to byteswap
 *
 *  @discussion swap byteswaps a UInt16 
 *
 *  @return Byteswapped UInt16
 */

- (UInt16)swap:(UInt16)s
{
 UInt16 temp = s << 8;
 temp |= (s >> 8);
 return temp;
}


- (void)scanTimer:(NSTimer *)timer  // stops scanning after a specified time
{
 [self.manager stopScan];
}


- (void)stopScan
{
 [self.manager stopScan];
}


- (void)disconnect:(CBPeripheral *)peripheral   // disconnect from a given peripheral
{
 [self.manager cancelPeripheralConnection:peripheral];
}


#pragma mark - basic operations for SerialGATT service

- (void)read:(CBPeripheral *)peripheral
{
 NSLog(@"begin reading");
    //[peripheral readValueForCharacteristic:dataRecvrCharacteristic];
 NSLog(@"now reading");
}


- (void)notify:(CBPeripheral *)peripheral on:(BOOL)on
{
 [self notification:SERVICE_UUID characteristicUUID:CHAR_UUID p:peripheral on:YES];
}


#pragma mark - CBCentralManager Delegates

- (void)centralManagerDidUpdateState:(CBCentralManager *)centralManager
{
 switch(centralManager.state)
    {
    case CBCentralManagerStatePoweredOn    : //[self.delegate scanForPeripherals];
         break;
    case CBCentralManagerStatePoweredOff   :
         break;
    case CBCentralManagerStateResetting    :
         break;
    case CBCentralManagerStateUnauthorized :
         break;
    case CBCentralManagerStateUnknown      :
         break;
    case CBCentralManagerStateUnsupported  :
         break;
    }
}


-(void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error   // callback after a disconnection is successful
{
 NSLog(@"Disconnected from the active peripheral");
 
 if (self.activePeripheral != nil)
    {
    [self.delegate didDisconnect:peripheral];
    self.activePeripheral = nil;
    }
}


-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
 NSLog(@"failed to connect to peripheral %@: %@", [peripheral name], [error localizedDescription]);
}


#pragma mark - CBPeripheral delegates


- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error
{
    
}


- (void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral error:(NSError *)error
{
    
}




/*
 *  @method didDiscoverCharacteristicsForService
 *
 *  @param peripheral Pheripheral that got updated
 *  @param service Service that characteristics where found on
 *  @error error Error message if something went wrong
 *
 *  @discussion didDiscoverCharacteristicsForService is called when CoreBluetooth has discovered 
 *  characteristics on a service, on a peripheral after the discoverCharacteristics routine has been called on the service
 *
 */



- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
 if (!error)
    {
    NSLog(@"Updated notification state for characteristic with UUID %s on service with  UUID %s on peripheral with UUID %s\r\n", [self CBUUIDToString:characteristic.UUID], [self CBUUIDToString:characteristic.service.UUID], [self UUIDToString:(__bridge CFUUIDRef )peripheral.identifier]);
    [self.delegate setConnect];
    }
 else
    {
    NSLog(@"Error in setting notification state for characteristic with UUID %s on service with  UUID %s on peripheral with UUID %s\r\n", [self CBUUIDToString:characteristic.UUID],[self CBUUIDToString:characteristic.service.UUID],[self UUIDToString:(__bridge CFUUIDRef )peripheral.identifier]);
    NSLog(@"Error code was %s\r\n",[[error description] cStringUsingEncoding:NSStringEncodingConversionAllowLossy]);
    }
}

/*
 *  @method CBUUIDToString
 *
 *  @param UUID UUID to convert to string
 *
 *  @returns Pointer to a character buffer containing UUID in string representation
 *
 *  @discussion CBUUIDToString converts the data of a CBUUID class to a character pointer for easy printout using printf()
 *
 */
- (const char *)CBUUIDToString:(CBUUID *)UUID
{
 return [[UUID.data description] cStringUsingEncoding:NSStringEncodingConversionAllowLossy];
}


/*
 *  @method UUIDToString
 *
 *  @param UUID UUID to convert to string
 *
 *  @returns Pointer to a character buffer containing UUID in string representation
 *
 *  @discussion UUIDToString converts the data of a CFUUIDRef class to a character pointer for easy printout using printf()
 *
 */
- (const char *)UUIDToString:(CFUUIDRef)UUID
{
 if (!UUID) return "NULL";
 
 CFStringRef s = CFUUIDCreateString(NULL, UUID);
 
 return CFStringGetCStringPtr(s, 0);
}

/*
 *  @method compareCBUUID
 *
 *  @param UUID1 UUID 1 to compare
 *  @param UUID2 UUID 2 to compare
 *
 *  @returns 1 (equal) 0 (not equal)
 *
 *  @discussion compareCBUUID compares two CBUUID's to each other and returns 1 if they are equal and 0 if they are not
 *
 */

- (int)compareCBUUID:(CBUUID *)UUID1 UUID2:(CBUUID *)UUID2
{
 char b1[16];
 char b2[16];
 [UUID1.data getBytes:b1 length:32];    // BENBEN
 [UUID2.data getBytes:b2 length:32];
 
 if (memcmp(b1, b2, UUID1.data.length) == 0) return 1;
 else                                        return 0;
}


/*
 *  @method findServiceFromUUID:
 *
 *  @param UUID CBUUID to find in service list
 *  @param p Peripheral to find service on
 *
 *  @return pointer to CBService if found, nil if not
 *
 *  @discussion findServiceFromUUID searches through the services list of a peripheral to find a 
 *  service with a specific UUID
 *
 */
- (CBService *)findServiceFromUUIDEx:(CBUUID *)UUID p:(CBPeripheral *)p
{
 for (int i = 0; i < p.services.count; i++)
     {
     CBService *s = [p.services objectAtIndex:i];
     if ([self compareCBUUID:s.UUID UUID2:UUID]) return s;
     }
 
 return nil; //Service not found on this peripheral
}

/*
 *  @method findCharacteristicFromUUID:
 *
 *  @param UUID CBUUID to find in Characteristic list of service
 *  @param service Pointer to CBService to search for charateristics on
 *
 *  @return pointer to CBCharacteristic if found, nil if not
 *
 *  @discussion findCharacteristicFromUUID searches through the characteristic list of a given service 
 *  to find a characteristic with a specific UUID
 *
 */
- (CBCharacteristic *)findCharacteristicFromUUIDEx:(CBUUID *)UUID service:(CBService*)service
{
 for (int i = 0; i < service.characteristics.count; i++)
     {
     CBCharacteristic *c = [service.characteristics objectAtIndex:i];
     if ([self compareCBUUID:c.UUID UUID2:UUID]) return c;
     }
 
 return nil; //Characteristic not found on this service
}


/*!
 *  @method notification:
 *
 *  @param serviceUUID Service UUID to read from (e.g. 0x2400)
 *  @param characteristicUUID Characteristic UUID to read from (e.g. 0x2401)
 *  @param p CBPeripheral to read from
 *
 *  @discussion Main routine for enabling and disabling notification services. It converts integers
 *  into CBUUID's used by CoreBluetooth. It then searches through the peripherals services to find a
 *  suitable service, it then checks that there is a suitable characteristic on this service.
 *  If this is found, the notfication is set.
 *
 */
- (void)notification:(int)serviceUUID characteristicUUID:(int)characteristicUUID p:(CBPeripheral *)p on:(BOOL)on
{
 UInt16 s = [self swap:serviceUUID];
 UInt16 c = [self swap:characteristicUUID];
 NSData *sd = [[NSData alloc] initWithBytes:(char *)&s length:2];
 NSData *cd = [[NSData alloc] initWithBytes:(char *)&c length:2];
 CBUUID *su = [CBUUID UUIDWithData:sd];
 CBUUID *cu = [CBUUID UUIDWithData:cd];
 CBService *service = [self findServiceFromUUIDEx:su p:p];
 
 if (!service)
    {
    NSLog(@"Could not find service with UUID %s on peripheral with UUID %s", [self CBUUIDToString:su], [self UUIDToString:(__bridge CFUUIDRef )p.identifier]);
    return;
    }
 
 CBCharacteristic *characteristic = [self findCharacteristicFromUUIDEx:cu service:service];
 
 if (!characteristic)
    {
    NSLog(@"Could not find characteristic with UUID %s on service with UUID %s on peripheral with UUID %s", [self CBUUIDToString:cu], [self CBUUIDToString:su], [self UUIDToString:(__bridge CFUUIDRef )p.identifier]);
    return;
    }
 
 [p setNotifyValue:on forCharacteristic:characteristic];
}


/*!
 *  @method readValue:
 *
 *  @param serviceUUID Service UUID to read from (e.g. 0x2400)
 *  @param characteristicUUID Characteristic UUID to read from (e.g. 0x2401)
 *  @param p CBPeripheral to read from
 *
 *  @discussion Main routine for read value request. It converts integers into
 *  CBUUID's used by CoreBluetooth. It then searches through the peripherals services to find a
 *  suitable service, it then checks that there is a suitable characteristic on this service. 
 *  If this is found, the read value is started. When value is read the didUpdateValueForCharacteristic 
 *  routine is called.
 *
 *  @see didUpdateValueForCharacteristic
 */

- (void)readValue:(int)serviceUUID characteristicUUID:(int)characteristicUUID p:(CBPeripheral *)p
{
 NSLog(@"In read Value");
 UInt16 s = [self swap:serviceUUID];
 UInt16 c = [self swap:characteristicUUID];
 NSData *sd = [[NSData alloc] initWithBytes:(char *)&s length:2];
 NSData *cd = [[NSData alloc] initWithBytes:(char *)&c length:2];
 CBUUID *su = [CBUUID UUIDWithData:sd];
 CBUUID *cu = [CBUUID UUIDWithData:cd];
 CBService *service = [self findServiceFromUUIDEx:su p:p];
 
 if (!service)
    {
    NSLog(@"Could not find service with UUID %s on peripheral with UUID %s", [self CBUUIDToString:su], [self UUIDToString:(__bridge CFUUIDRef )p.identifier]);
    return;
    }
 
 CBCharacteristic *characteristic = [self findCharacteristicFromUUIDEx:cu service:service];
 
 if (!characteristic)
    {
    NSLog(@"Could not find characteristic with UUID %s on service with UUID %s on peripheral with UUID %s", [self CBUUIDToString:cu], [self CBUUIDToString:su],[self UUIDToString:(__bridge CFUUIDRef )p.identifier]);
    return;
    }  
 
 [p readValueForCharacteristic:characteristic];
}

@end
