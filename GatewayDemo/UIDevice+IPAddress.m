//
//  UIDevice+IPAddress.m
//  GatewayDemo
//
//  Created by LS on 05/05/2017.
//  Copyright © 2017 LS. All rights reserved.
//

#import "UIDevice+IPAddress.h"
#include <ifaddrs.h>
#include <arpa/inet.h>
#include <sys/sysctl.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <resolv.h>
#include <dns.h>
#include "route.h"

#define CTL_NET         4               /* network, see socket.h */

#define ROUNDUP(a) \
((a) > 0 ? (1 + (((a) - 1) | (sizeof(long) - 1))) : sizeof(long))

@implementation UIDevice (IPAddress)

- (NSString *)localIPAddress {
    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while (temp_addr != NULL) {
            if (temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if ([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(interfaces);
    return address;
}

- (NSString *)gatewayIPAddress {
    NSString *address = nil;
    
    /* net.route.0.inet.flags.gateway */
    int mib[] = {CTL_NET,
                 PF_ROUTE,
                 0,
                 AF_INET,
                 NET_RT_FLAGS,
                 RTF_GATEWAY};
    size_t size;
    char *buf, *p;
    struct rt_msghdr * rt;
    struct sockaddr * sa;
    struct sockaddr * sa_tab[RTAX_MAX];
    int i;
    int r = -1;
    
    if(sysctl(mib, sizeof(mib)/sizeof(int), 0, &size, 0, 0) < 0) {
        address = @"192.168.0.1";
    }
    
    if(size > 0) {
        buf = malloc(size);
        if(sysctl(mib, sizeof(mib)/sizeof(int), buf, &size, 0, 0) < 0) {
            address = @"192.168.0.1";
        }

        for(p = buf; p < buf + size; p += rt->rtm_msglen) {
            rt = (struct rt_msghdr *)p;
            sa = (struct sockaddr *)(rt + 1);
            for(i = 0; i < RTAX_MAX; i++) {
                if(rt->rtm_addrs & (1 << i)) {
                    sa_tab[i] = sa;
                    sa = (struct sockaddr *)((char *)sa + ROUNDUP(sa->sa_len));
                } else {
                    sa_tab[i] = NULL;
                }
            }
            
            if(((rt->rtm_addrs & (RTA_DST|RTA_GATEWAY)) == (RTA_DST|RTA_GATEWAY))
               && sa_tab[RTAX_DST]->sa_family == AF_INET
               && sa_tab[RTAX_GATEWAY]->sa_family == AF_INET) {
                unsigned char octet[4]  = {0,0,0,0};
                int i;
                for (i = 0; i < 4; i++){
                    octet[i] = (((struct sockaddr_in *)(sa_tab[RTAX_GATEWAY]))->sin_addr.s_addr >> (i*8)) & 0xFF;
                }
                if(((struct sockaddr_in *)sa_tab[RTAX_DST])->sin_addr.s_addr == 0) {
                    in_addr_t addr = ((struct sockaddr_in *)(sa_tab[RTAX_GATEWAY]))->sin_addr.s_addr;
                    r = 0;
                    address = [NSString stringWithFormat:@"%s", inet_ntoa(*((struct in_addr*)&addr))];
                    break;
                }
            }
        }
        free(buf);
    }
    return address;
}


- (NSString *)localDnsServerIpAddress {
    // dont forget to link libresolv.lib
    NSMutableString *addresses = [[NSMutableString alloc] init];
    
    res_state res = malloc(sizeof(struct __res_state));
    
    int result = res_ninit(res);
    
    if (result == 0){
        for (int i = 0; i < res->nscount; i++){
            NSString *s = [NSString stringWithUTF8String :  inet_ntoa(res->nsaddr_list[i].sin_addr)];
            [addresses appendFormat:@"%@ ",s];
        }
    }
    else {
        [addresses appendString:@" res_init result != 0"];
    }
    
    return addresses;
}

@end
