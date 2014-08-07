//
//  YunJieKou.m
//  GuQuan
//
//  Created by Wu Guoquan on 14-8-7.
//  Copyright (c) 2014年 com.caibo-inc.guquan. All rights reserved.
//

#import "YunJieKou.h"

@implementation YunJieKou

@synthesize delegate = _delegate;

-(void)req:(NSString *)methodName
{
    [self req:methodName params:nil];
}

-(void)req:(NSString *)methodName params:(NSMutableDictionary *)params
{
    NSMutableDictionary *mDic;
    if(!params)
    {
        mDic = [[NSMutableDictionary alloc] initWithCapacity:0];
    }else{
        mDic = params;
    }
    
    [mDic setObject:YunJieKou_AppKey forKey:@"appkey"];
    [mDic setObject:YunJieKou_Version forKey:@"v"];
    [mDic setObject:[NSString stringWithFormat:@"%d",(int)[NSDate timeIntervalSinceReferenceDate]] forKey:@"timestamp"];
    [mDic setObject:methodName forKey:@"method"];
    [mDic setObject:@"json" forKey:@"format"];

    NSString *sign = [self getSign:mDic];
    NSString *urlString = [NSString stringWithFormat:@"%@?%@sign=%@",YunJieKou_Server,[self dicToString:mDic],sign];
    
    
    urlString = [urlString stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString: urlString]];
    [request setCachePolicy:NSURLRequestReloadIgnoringCacheData];
    [request setTimeoutInterval: 60];
    [request setHTTPShouldHandleCookies:FALSE];
    [request setHTTPMethod:@"GET"];
    // NSURLConnection* aSynConnection 可以申明为全局变量.
    // 在协议方法中，通过判断aSynConnection，来区分，是哪一个异步请求的返回数据。
    aSynConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    
}

-(NSString *)dicToString:(NSDictionary *)dic
{
    NSString *kvs = @"";
    for (NSString *key in dic) {
        
        kvs = [NSString stringWithFormat:@"%@%@=%@&",kvs,key,[self encode:dic[key]]];
    }
    
    return kvs;
}


-(NSString *)getSign:(NSDictionary *)params
{
    
    NSString *kvs = @"";
    for (NSString *key in params) {
        
        kvs = [NSString stringWithFormat:@"%@%@%@",kvs,key,[self encode:params[key]]];
    }
    
    kvs = [NSString stringWithFormat:@"%@%@%@",YunJieKou_AppSecret,kvs,YunJieKou_AppSecret];
    return  [self md5:kvs];
}


- (NSString *)md5:(NSString *)str
{
    const char *cStr = [str UTF8String];
    unsigned char result[16];
    CC_MD5(cStr, strlen(cStr), result); // This is the md5 call
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ]; 
}


-(NSString *)encode:(NSString *)strURL
{
    return (__bridge NSString *)CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                        (__bridge CFStringRef)strURL, NULL,
                                                                        (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                        kCFStringEncodingUTF8);
}


#pragma mark- NSURLConnectionDelegate 协议方法


- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)aResponse{
    returnInfoData=[[NSMutableData alloc] init];
}


- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    [returnInfoData appendData:data];
}


- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    if([_delegate respondsToSelector:@selector(yunjiekou:serverDataGetFailure:message:)])
    {
        [_delegate yunjiekou:self serverDataGetFailure:nil message:@"Network error"];
    }
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection{
    if( [connection isEqual: aSynConnection])
    {
        NSError *error;
        NSDictionary *respDic = [NSJSONSerialization JSONObjectWithData:returnInfoData
                                                                   options:NSJSONReadingMutableContainers
                                                                     error:&error];
        if(respDic)
        {
            if([_delegate respondsToSelector:@selector(yunjiekou:serverDataGetSuccess:)])
            {
                [_delegate yunjiekou:self serverDataGetSuccess:[respDic objectForKey:@"data"]];
            }
        }else{
            if([_delegate respondsToSelector:@selector(yunjiekou:serverDataGetFailure:message:)])
            {
                [_delegate yunjiekou:self serverDataGetFailure:nil message:@"Data deserialize failre"];
            }
        }

    }
}



@end
