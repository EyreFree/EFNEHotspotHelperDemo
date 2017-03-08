//
//  ViewController.m
//  EFNEHotspotHelperDemo
//
//  Created by EyreFree on 17/3/8.
//  Copyright © 2017年 EyreFree. All rights reserved.
//

#import "ViewController.h"
#import <NetworkExtension/NetworkExtension.h>

@interface ViewController ()

    @end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    [self scanWifiInfos];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)scanWifiInfos{
    NSLog(@"1.Start");

    NSMutableDictionary* options = [[NSMutableDictionary alloc] init];
    [options setObject:@"EFNEHotspotHelperDemo" forKey: kNEHotspotHelperOptionDisplayName];
    dispatch_queue_t queue = dispatch_queue_create("EFNEHotspotHelperDemo", NULL);

    NSLog(@"2.Try");
    BOOL returnType = [NEHotspotHelper registerWithOptions: options queue: queue handler: ^(NEHotspotHelperCommand * cmd) {

        NSLog(@"4.Finish");
        NEHotspotNetwork* network;
        if (cmd.commandType == kNEHotspotHelperCommandTypeEvaluate || cmd.commandType == kNEHotspotHelperCommandTypeFilterScanList) {
            // 遍历 WiFi 列表，打印基本信息
            for (network in cmd.networkList) {
                NSString* wifiInfoString = [[NSString alloc] initWithFormat: @"---------------------------\nSSID: %@\nMac地址: %@\n信号强度: %f\nCommandType:%ld\n---------------------------\n\n", network.SSID, network.BSSID, network.signalStrength, (long)cmd.commandType];
                NSLog(@"%@", wifiInfoString);

                // 检测到指定 WiFi 可设定密码直接连接
                if ([network.SSID isEqualToString: @"测试 WiFi"]) {
                    [network setConfidence: kNEHotspotHelperConfidenceHigh];
                    [network setPassword: @"123456789"];
                    NEHotspotHelperResponse *response = [cmd createResponse: kNEHotspotHelperResultSuccess];
                    NSLog(@"Response CMD: %@", response);
                    [response setNetworkList: @[network]];
                    [response setNetwork: network];
                    [response deliver];
                }
            }
        }
    }];

    // 注册成功 returnType 会返回一个 Yes 值，否则 No
    NSLog(@"3.Result: %@", returnType == YES ? @"Yes" : @"No");
}
    
    @end
