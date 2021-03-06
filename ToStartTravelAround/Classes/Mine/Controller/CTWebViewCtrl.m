//
//  CTWebViewCtrl.m
//  CTEntertainmentCat
//
//  Created by hjzhao on 15-7-24.
//  Copyright (c) 2015年 cheetah. All rights reserved.
//

#import "CTWebViewCtrl.h"
// 导入js交互接口文件
#import "MyJSInterface.h"
// 导入交互webViuew的类
#import "EasyJSWebView.h"

@interface CTWebViewCtrl ()<UIWebViewDelegate>
{
    EasyJSWebView *_webView;
}
@end

@implementation CTWebViewCtrl

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _webView = [[EasyJSWebView alloc]initWithFrame:self.view.bounds];
    _webView.delegate = self;
#warning webView基本玩法
//    NSURLRequest *Request = [NSURLRequest requestWithURL:[NSURL URLWithString:self.mediaUrl]];
//    [webView loadRequest:Request];
#warning webView高级第一种玩法
//    NSString *htmlString = [NSString stringWithFormat:@"<h3 class='title title-1'>一山书画社介绍：</h3><p>&nbsp;一山书画社始建于2014年，是目前广州师资队伍平均学历最高，综合素质最强的书画培训创业团队，师资队伍由清华，广美，广工科班书法和国画研究生组建而成，一山书画社才刚刚建立，其中亦有很多不完善的地方，请亲爱的粑粑麻麻多给我们提意见，我们将真诚的为你们服务，大家多多支持。&nbsp;</p><p>我们听不到，是因为润物无声。我们看不到，是因为潜移默化。&nbsp;书法国画可以改变孩子们的性格和行为，如同在心中播下了一颗希望的种子，终将向着阳光破土而出！</p><p class='pic'><img src='http://pic.108tian.com/pic/u_d19baad62877886d0d4305deabc8d499.jpg' alt=''></p>"];
//    // 读取html字符串内容
//    [_webView loadHTMLString:htmlString baseURL:nil];

#warning webView高级第二种玩法
//    NSURLRequest *Request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://m.9skg.com/market/1_5_0/home.html?20150414172101"]];
//    [webView loadRequest:Request];
#warning webView高级第三种玩法
    
    // 创建oc与js交互对象
    MyJSInterface *jsInterface = [MyJSInterface alloc];
    // js回调block
    jsInterface.contentBlock = ^(id content)
    {
        NSLog(@"方法名字是%@",content[@"param1"]);
        self.navigationItem.title = content[@"param2"];
    };
    // 添加到课交互webView上
    [_webView addJavascriptInterfaces:jsInterface WithName:@"MyJSTest"];
    // 在test.html文件中的 js通过MyJSInterface调用OC方法
    [_webView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"home" ofType:@"html"]isDirectory:NO]]];
    
    
    // 导航栏右边按钮
    UIBarButtonItem *right= [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"iconfont_qr.png"] style:UIBarButtonItemStylePlain target:self action:@selector(clickSmallPic)];
    self.navigationItem.rightBarButtonItem = right;
    [self.view addSubview:_webView];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self dismissViewControllerAnimated:YES completion:^{
        ;
    }];
}
#pragma mark - ============== 点击触发事件 =============

- (void)clickSmallPic
{
    // 调用webView上的javascript方法：play()
    [_webView stringByEvaluatingJavaScriptFromString:@"play('123','567');"];
    NSString *jsMethod =[NSString stringWithFormat:
                         // 创建javascript的标签
                         // 第一步效果：<script></script>
                         @"var script = document.createElement('script');"
                         // 把标签上的type设置成 type="text/javascript"
                         // 第二步效果： <script type="text/javascript"></script>
                         "script.type = 'text/javascript';"
                         // 把标签上面的内容增加 function ResizeImages() {var myimg,oldwidth;var maxwidth=%f;for(i=0;i <document.images.length;i++){myimg = document.images[i];if(myimg.width > maxwidth){oldwidth = myimg.width;myimg.width = maxwidth;}}}\字符串
                         // 第三步效果： <script type="text/javascript">function ResizeImages() {var myimg,oldwidth;var maxwidth=%f;for(i=0;i <document.images.length;i++){myimg = document.images[i];if(myimg.width > maxwidth){oldwidth = myimg.width;myimg.width = maxwidth;}}}\</script>
                         "script.text = \"function ResizeImages() { "
                         "var myimg,oldwidth;"
                         "var maxwidth=%f;"
                         "for(i=0;i <document.images.length;i++){"
                         "myimg = document.images[i];"
                         "if(myimg.width > maxwidth){"
                         "oldwidth = myimg.width;"
                         "myimg.width = maxwidth;"
                         "}"
                         "}"
                         "}\";"
                         // 把创建成功的标签放到我们的html的head标签中
                         "document.getElementsByTagName('head')[0].appendChild(script);",[UIScreen mainScreen].bounds.size.width - 20];
    ;
    
    //拦截网页图片  并修改图片大小
    [_webView stringByEvaluatingJavaScriptFromString:jsMethod];
    // 调用webView上的javascript方法：ResizeImages()
    [_webView stringByEvaluatingJavaScriptFromString:@"ResizeImages();"];
}

#pragma mark - ============== 各协议方法 ========
#pragma mark - UIWebViewDelegate

// webView将要开始加载
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    // 判断内容的类型是什么
    if ([request.URL.path isEqualToString:@"/web"]) {
    }
    else if ([request.URL.path isEqualToString:@"/chaoshi"])
    {
        NSString *parmasString = request.URL.query;
        // catId=6321，title=果汁/奶茶
        NSArray *parmasArray =[parmasString componentsSeparatedByString:@"&"];
        NSMutableDictionary *parmaDic = [NSMutableDictionary dictionary];
        
        for (NSString *parma in parmasArray) {
            [parmaDic setValue:[[parma componentsSeparatedByString:@"="] objectAtIndex:1] forKey:[[parma componentsSeparatedByString:@"="] objectAtIndex:0]];
        }
    }
    return YES;
}

// webView已经开始加载
- (void)webViewDidStartLoad:(UIWebView *)webView
{
    
}

// webView完成加载
- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    
}

// webView失败加载
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    
}
@end
