//
//  nodetun.m
//

#import "NodeTun.h"

#include <sys/types.h>
#include <sys/stat.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <signal.h>
#include <sys/wait.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <netinet/in_systm.h>
#include <netinet/in.h>
#include <netinet/ip.h>
#include <net/if.h>
#include <arpa/inet.h>
#include <errno.h>
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/kern_control.h>
#include <sys/sys_domain.h>
#include <net/if_utun.h>

int open_utun();

@implementation NodeTun

- (void)getVersionWithReply:(void(^)(NSString * version))reply
{
    reply([[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]);
}

- (void)openTunFdWithReply:(void(^)(NSError * error, NSFileHandle *tunHandle, NSString *deviceName))reply {
    NSError *error = nil;
    NSFileHandle *fileHandle = nil;
    NSString *deviceName = nil;
    
    int tunFd = open_utun(&deviceName);
    
    if(tunFd < 0) {
        error = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:nil];
    } else {
        fileHandle = [[NSFileHandle alloc] initWithFileDescriptor:tunFd closeOnDealloc:NO];
    }
    
    reply(error, fileHandle, deviceName);
    
    if(tunFd != -1) {
        close(tunFd);
    }
}

- (void)configureInterface:(NSString *)interface localAddress:(NSString *)localIP remoteAddress:(NSString *)remoteIP subnetMask:(NSString *)subnetMask withReply:(void(^)(int status))reply {
    NSArray *args = @[interface, @"inet", localIP, remoteIP, @"netmask", subnetMask];
    
    NSTask *task = [NSTask launchedTaskWithLaunchPath:@"/sbin/ifconfig" arguments:args];
    
    [task launch];
    [task waitUntilExit];
    
    reply([task terminationStatus]);
}

@end

int open_utun(NSString **outDeviceName) {
    int tun_fd = socket(PF_SYSTEM, SOCK_DGRAM, SYSPROTO_CONTROL);
    if (tun_fd >= 0) {
        struct sockaddr_ctl sc = {0,};
        struct ctl_info ci = {0,};
        
        snprintf(ci.ctl_name, sizeof(ci.ctl_name), UTUN_CONTROL_NAME);
        
        if (ioctl(tun_fd, CTLIOCGINFO, &ci) != -1) {
            sc.sc_id = ci.ctl_id;
            sc.sc_len = sizeof(sc);
            sc.sc_family = AF_SYSTEM;
            sc.ss_sysaddr = AF_SYS_CONTROL;
            
            for(int unit_nr = 0; unit_nr < 254; unit_nr++)
            {
                sc.sc_unit = unit_nr + 1;
                
                if (connect(tun_fd, (struct sockaddr * )&sc, sizeof(sc)) == 0) {
                    NSString *deviceName = [NSString stringWithFormat:@"utun%d", unit_nr];
                    
                    if(outDeviceName)
                    {
                        *outDeviceName = deviceName;
                    }
                    
                    NSLog(@"Created %@", deviceName);
                    
                    return tun_fd;
                }
            };
            
            NSLog(@"Couldn't find an availble utun device");
        } else {
            NSLog(@"Failed to query utun control id: %s\n", strerror(errno));
        }
        
        close(tun_fd);
    } else {
        NSLog(@"Failed to open SYSPROTO_CONTROL socket: %s", strerror(errno));
    }
    return -1;
}
