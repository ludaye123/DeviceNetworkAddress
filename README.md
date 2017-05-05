# DeviceNetworkAddress

获取设备本地的IP、Gateway、DNS Server IP

```
UIDevice+IPAddress.h

/**
 * 获取设备本地的IP地址
 * @return 本地IP地址
 */
- (NSString *)localIPAddress;

/**
 * 获取设备本地网关地址
 * @return 本地网关地址
 */
- (NSString *)gatewayIPAddress;

/**
 * 获取设备本地DNS服务器地址
 * @return 本地DNS服务器地址
 */
- (NSString *)localDnsServerIpAddress;
```

