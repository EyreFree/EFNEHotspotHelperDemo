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

@property (nonatomic, strong) UITextView *outputLabel;
@property (nonatomic, strong) UIButton *settingButton;
@property (nonatomic, copy) NSString *infoString;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // 添加控件
    [self addControl];

    // 根据扫描任务添加结果设置按钮状态
    [self.settingButton setEnabled: [self scanWifiInfo]];

    // 添加进入前台时的刷新
    [self observeApplicationNotifications];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear: animated];

    [self refresh];
}

- (void)addControl {
    CGSize screenSize = [UIScreen mainScreen].bounds.size;

    self.outputLabel = [[UITextView alloc] initWithFrame: CGRectMake(3, 23, screenSize.width - 6, screenSize.height - 89)];
    self.outputLabel.font = [UIFont systemFontOfSize: 13];
    self.outputLabel.layer.borderWidth = 1;
    self.outputLabel.editable = NO;
    self.outputLabel.layer.borderColor = [[UIColor blackColor] CGColor];
    [self.view addSubview: self.outputLabel];

    self.settingButton = [[UIButton alloc] initWithFrame: CGRectMake(3, screenSize.height - 64, screenSize.width - 6, 60)];
    self.settingButton.titleLabel.font = [UIFont systemFontOfSize: 20];
    [self.settingButton setTitle: @"Open WiFi Setting" forState: UIControlStateNormal];
    [self.settingButton setTitleColor: [UIColor blackColor] forState: UIControlStateNormal];
    self.settingButton.layer.borderWidth = 1;
    self.settingButton.layer.borderColor = [[UIColor blackColor] CGColor];
    [self.settingButton addTarget: self action:@selector(openWiFiSetting) forControlEvents: UIControlEventTouchUpInside];
    [self.view addSubview: self.settingButton];
}

- (BOOL)scanWifiInfo {
    NSLog(@"1.Start");
    self.outputLabel.text = @"1.Start";

    NSMutableDictionary* options = [[NSMutableDictionary alloc] init];
    [options setObject:@"EFNEHotspotHelperDemo" forKey: kNEHotspotHelperOptionDisplayName];
    dispatch_queue_t queue = dispatch_queue_create("EFNEHotspotHelperDemo", NULL);

    NSLog(@"2.Try");
    self.outputLabel.text = @"2.Try";

    __weak typeof(self) weakself = self;
    BOOL returnType = [NEHotspotHelper registerWithOptions: options queue: queue handler: ^(NEHotspotHelperCommand * cmd) {

        NSLog(@"4.Finish");

        NSMutableString* resultString = [[NSMutableString alloc] initWithString: @""];

        NEHotspotNetwork* network;
        if (cmd.commandType == kNEHotspotHelperCommandTypeEvaluate || cmd.commandType == kNEHotspotHelperCommandTypeFilterScanList) {
            // 遍历 WiFi 列表，打印基本信息
            for (network in cmd.networkList) {
                NSString* wifiInfoString = [[NSString alloc] initWithFormat: @"SSID: %@\nMac地址: %@\n信号强度: %f\nCommandType:%ld\n\n",
                                            network.SSID, network.BSSID, network.signalStrength, (long)cmd.commandType];
                NSLog(@"%@", wifiInfoString);
                [resultString appendString: wifiInfoString];

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

        weakself.infoString = resultString;
    }];

    // 注册成功 returnType 会返回一个 Yes 值，否则 No
    NSString* logString = [[NSString alloc] initWithFormat: @"3.Result: %@", returnType == YES ? @"Yes" : @"No"];
    NSLog(@"%@", logString);
    self.outputLabel.text = logString;

    return returnType;
}

// 打开 无线局域网设置
- (void)openWiFiSetting {
    NSURL* urlCheck1 = [NSURL URLWithString: @"App-Prefs:root=WIFI"];
    NSURL* urlCheck2 = [NSURL URLWithString: @"prefs:root=WIFI"];
    NSURL* urlCheck3 = [NSURL URLWithString: UIApplicationOpenSettingsURLString];

    NSLog(@"Try to open WiFi Setting, waiting...");
    self.outputLabel.text = @"Try to open WiFi Setting, waiting...";

    if ([[UIApplication sharedApplication] canOpenURL: urlCheck1]) {
        [[UIApplication sharedApplication] openURL: urlCheck1];
    } else if ([[UIApplication sharedApplication] canOpenURL: urlCheck2]) {
        [[UIApplication sharedApplication] openURL: urlCheck2];
    } else if ([[UIApplication sharedApplication] canOpenURL: urlCheck3]) {
        [[UIApplication sharedApplication] openURL: urlCheck3];
    } else {
        NSLog(@"Unable to open WiFi Setting!");
        self.outputLabel.text = @"Unable to open WiFi Setting!";

        return;
    }
    NSLog(@"Open WiFi Setting successful.");
    self.outputLabel.text = @"Open WiFi Setting successful.";
}

// 从设置页或者其他地方回来刷新
- (void)observeApplicationNotifications {
    [[NSNotificationCenter defaultCenter] removeObserver: self];

    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(refresh)
                                                 name: UIApplicationWillEnterForegroundNotification
                                               object: nil];

    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(refresh)
                                                 name: UIApplicationDidBecomeActiveNotification
                                               object: nil];
}

// 刷新获取到的 WiFi 信息
- (void)refresh {
    if (self.infoString != nil && ![self.infoString isEqual: @""]) {
        self.outputLabel.text = self.infoString;
    }
}

@end
