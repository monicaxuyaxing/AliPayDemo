//
//  ViewController.m
//  AliPayXYXDemo
//
//  Created by monica on 2018/5/10.
//  Copyright © 2018年 xyx. All rights reserved.
//

#import "ViewController.h"
#import <AlipaySDK/AlipaySDK.h> //支付宝SDK
#import "APOrderInfo.h"     //订单模型
#import "APRSASigner.h"  //支付宝签名类


#define SHAlipayAPPID       @"请配置你的AppID"
//支付宝私钥（用户自主生成，使用pkcs8格式的私钥）
#define SHAlipayPrivateKey  @"请配置你的支付宝pkcs8私钥"
//应用注册scheme,在AliSDKDemo-Info.plist定义URL types
#define SHURLScheme         @"请前往Info.plist定义URL types"
#define MXUrlAlipay       @"alipay.trade.app.pay"


@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{

    /*=========================================================*/
    /*====客户端调用支付宝支付（实际操作请放到服务端）=================*/
    /*=========================================================*/
    
    //AppId和PrivateKey没有配置下的提示
    if (  [SHAlipayAPPID length] == 0
        ||[SHAlipayPrivateKey length] == 0
        ||[SHAlipayAPPID isEqualToString:@"请配置你的AppID"]
        ||[SHAlipayPrivateKey isEqualToString:@"请配置你的支付宝pkcs8私钥"])
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示"
                                                        message:@"缺少appId或者私钥。"
                                                       delegate:self
                                              cancelButtonTitle:@"确定"
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    //商品价格
    NSString *price = [NSString stringWithFormat:@"%.2f", 0.01];
    
    
    //将商品信息赋予AlixPayOrder的成员变量
    APOrderInfo* order = [APOrderInfo new];
    
    // NOTE: app_id设置
    order.app_id = SHAlipayAPPID;
    
    // NOTE: 支付接口名称
    order.method = @"alipay.trade.app.pay";
    
    // NOTE: 参数编码格式
    order.charset = @"utf-8";
    
    // NOTE: 当前时间点
    NSDateFormatter* formatter = [NSDateFormatter new];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    order.timestamp = [formatter stringFromDate:[NSDate date]];
    
    // NOTE: 支付版本
    order.version = @"1.0";
    
    // NOTE: sign_type 根据商户设置的私钥来决定
    order.sign_type = @"RSA";
    
    // NOTE: 商品数据
    order.biz_content = [APBizContent new];
    order.biz_content.body = @"我是测试数据";
    order.biz_content.subject = @"1";
    order.biz_content.out_trade_no = [self generateTradeNO]; //订单ID（由商家自行制定）
    order.biz_content.timeout_express = @"30m"; //超时时间设置
    order.biz_content.total_amount = [NSString stringWithFormat:@"%.2f", 0.01]; //商品价格
    
    //将商品信息拼接成字符串
    NSString *orderInfo = [order orderInfoEncoded:NO];
    NSString *orderInfoEncoded = [order orderInfoEncoded:YES];
    NSLog(@"orderSpec = %@",orderInfo);
    
    // NOTE: 获取私钥并将商户信息签名，外部商户的加签过程请务必放在服务端，防止公私钥数据泄露；
    //       需要遵循RSA签名规范，并将签名字符串base64编码和UrlEncode
    NSString *signedString = nil;
    APRSASigner* signer = [[APRSASigner alloc] initWithPrivateKey:SHAlipayPrivateKey];
    signedString = [signer signString:orderInfo withRSA2:NO];
    
    
    // NOTE: 如果加签成功，则继续执行支付
    if (signedString != nil) {
        //应用注册scheme,在AliSDKDemo-Info.plist定义URL types
        NSString *appScheme = SHURLScheme;
        
        // NOTE: 将签名成功字符串格式化为订单字符串,请严格按照该格式
        NSString *orderString = [NSString stringWithFormat:@"%@&sign=%@",
                                 orderInfoEncoded, signedString];
        
        // NOTE: 调用支付结果开始支付
        [[AlipaySDK defaultService] payOrder:orderString fromScheme:appScheme callback:^(NSDictionary *resultDic) {
            NSLog(@"reslut = %@",resultDic);
        }];
    }
}

#pragma mark - Private Method

//==============产生随机订单号==============

- (NSString *)generateTradeNO
{
    static int kNumber = 15;
    
    NSString *sourceStr = @"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    NSMutableString *resultStr = [[NSMutableString alloc] init];
    srand((unsigned)time(0));
    for (int i = 0; i < kNumber; i++)
    {
        unsigned index = rand() % [sourceStr length];
        NSString *oneStr = [sourceStr substringWithRange:NSMakeRange(index, 1)];
        [resultStr appendString:oneStr];
    }
    return resultStr;
}

@end
