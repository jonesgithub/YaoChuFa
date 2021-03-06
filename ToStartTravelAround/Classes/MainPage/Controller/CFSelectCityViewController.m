//
//  CFSelectCityViewController.m
//  ToStartTravelAround
//
//  Created by mac on 15/8/1.
//  Copyright (c) 2015年 mac. All rights reserved.
//

#import "CFSelectCityViewController.h"
#import "CFVSelectCityView.h"
#import "CFSearchBar.h"
#import "Masonry.h"
#import "CFNetWork.h"
#import "CFCurrentLocation.h"
#import <CoreLocation/CoreLocation.h>
#import "CFCurrentLocationTableViewCell.h"
#import "CFHotCityTableViewCell.h"
#import "CFSortCity.h"
#import "CFSearchResultViewController.h"
#import "CFHeader.h"
#import "CFHistoryCityViewCell.h"
#import "CFShareInstance.h"
#import "MJNIndexView.h"
@interface CFSelectCityViewController ()<UITableViewDelegate,UITableViewDataSource,CLLocationManagerDelegate,UISearchBarDelegate,MJNIndexViewDataSource>
{
    CFVSelectCityView *_selectCityView; //定义这个控制器的View
    CFSearchBar *_searchBar;
    NSArray *_sectionTitleArr;//组的名字
    NSArray *_hotCityArr;//接收热门城市数据的数组
    NSArray *_allCityArr;//接收所有城市数据的数组
    NSArray *_cityWithSectionArr;
    NSArray *_sectionIndexArr;
    NSString *_cityName;//记录定位得到的城市名
    NSDictionary *_cityInfodic;//记录城市编码
    
}
@property (nonatomic, strong) MJNIndexView *indexView;
@property(nonatomic,strong)NSMutableArray *sectionNameArr;//分组名称
@property(nonatomic,strong)NSMutableArray *sortAllCityArr;//根据ABC...排序后的数组
@property (nonatomic ,strong) CLGeocoder *geocoder;//反地理编码
@property(nonatomic,strong)CLLocationManager *locationManager;//定位管理者
@property(nonatomic,strong)CLLocation *currentLocation;//储存当前的位置信息
@property(nonatomic,strong)CFSearchResultViewController *citySearchResult;//搜索结果控制器
@property(nonatomic,strong)NSMutableArray *historyCityArr;//接收历史城市数据的数组
@property(nonatomic,strong)UIView *cover;//遮盖曾
@end

@implementation CFSelectCityViewController
#pragma mark =======================懒加载=======================
- (CLLocationManager *)locationManager
{
    if (!_locationManager) {
        _locationManager = [CLLocationManager new];
    }
    return _locationManager;
}

- (CLGeocoder *)geocoder
{
    if (!_geocoder) {
        _geocoder = [[CLGeocoder alloc] init];
    }
    return _geocoder;
}
- (NSMutableArray *)sortAllCity
{
    if (!_sortAllCityArr) {
        _sortAllCityArr = [[NSMutableArray alloc]init];
    }
    return _sortAllCityArr;
}
- (NSMutableArray *)historyCityArr
{
    if (!_historyCityArr) {
        _historyCityArr = [[NSMutableArray alloc]init];
    }
    return _historyCityArr;
}

//城市搜索的结果
- (CFSearchResultViewController *)citySearchResult
{
    if (!_citySearchResult) {
        _citySearchResult  = [[CFSearchResultViewController alloc]init];
        [self addChildViewController:_citySearchResult];
        [self.view addSubview:self.citySearchResult.view];

        [self.citySearchResult.view mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(_selectCityView.tableView.mas_left).offset(0);
            make.right.equalTo(_selectCityView.tableView.mas_right).offset(0);
            make.top.equalTo(_selectCityView.tableView.mas_top).offset(0);
            make.bottom.equalTo(_selectCityView.tableView.mas_bottom).offset(0);

        }];
    }
    return _citySearchResult;
}

#pragma mark =======================视图相关=======================
- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"选择城市";
    _sectionIndexArr = [NSMutableArray arrayWithArray:@[@"#",@"#",@"热门",@"A",@"B",@"C",@"D",@"E", @"F",@"G",@"H",@"J",@"K",@"L",@"M",@"N",@"P",@"Q",@"R",@"S", @"T",@"W",@"X",@"Y",@"Z"]];

    [self createView];//调用创建View的方法
    [self getCurrentLocation];
    [self cityDataRequest];
    

    
}

//创建视图
- (void)createView
{
    //初始化TableView
    _selectCityView = [[CFVSelectCityView alloc]initWithFrame:self.view.bounds];
    _selectCityView.tableView.delegate = self;
    _selectCityView.tableView.showsVerticalScrollIndicator = NO;
    _selectCityView.tableView.dataSource = self;
    self.view = _selectCityView;
    //创建自定义索引
    self.indexView = [[MJNIndexView alloc]initWithFrame:CGRectMake(0, 60, IphoneWidth, self.view.height-130)];
    self.indexView.dataSource = self;
    self.indexView.curtainColor = [UIColor lightGrayColor];
    self.indexView.fontColor = [UIColor orangeColor];
    [self.view addSubview:self.indexView];
    //创建遮盖曾
    _cover = [[UIView alloc] init];
    self.cover.alpha = 0;
    _cover.backgroundColor = [UIColor blackColor];
    [self.view addSubview:_cover];
#warning 系统自带的索引属性设置
    //设置索引的属性
//    _selectCityView.tableView.sectionIndexColor = [UIColor orangeColor];
//    _selectCityView.tableView.sectionIndexBackgroundColor= [UIColor clearColor];
    //设置搜搜索栏
    UISearchBar *searchBar = [[UISearchBar alloc]init];
    
    searchBar.placeholder = @"请输入搜索城市";
    searchBar.delegate = self;
    searchBar.tintColor = CFColor(32, 191, 179);
    //修改系统"取消"按钮颜色
    NSMutableDictionary *textAttrs = [NSMutableDictionary dictionary];
    textAttrs[NSForegroundColorAttributeName] = CFColor(32, 191, 179);
  
    [[UIBarButtonItem appearanceWhenContainedIn:[UISearchBar class], nil] setTitle:@"取消"];
    [[UIBarButtonItem appearanceWhenContainedIn:[UISearchBar class], nil] setTitleTextAttributes:textAttrs forState:UIControlStateNormal];
    //设置背景图片
    [searchBar setBackgroundImage:[UIImage imageNamed:@"bg_login_textfield"]];
    //添加约束
    [_selectCityView.searchView addSubview:searchBar];

    [searchBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_selectCityView.mas_left).offset(10);
        make.right.equalTo(_selectCityView.mas_right).offset(-10);
        make.top.equalTo(_selectCityView.searchView.mas_top).offset(4.5);
        make.bottom.equalTo(_selectCityView.searchView.mas_bottom).offset(-4.5);
        
    }];

}
#pragma mark =======================获取当前位置=======================
- (void)getCurrentLocation
{
    //判断设备系统版本
    if (DeviceVersion >=8.0) {
        //申请定位权限
        [self.locationManager requestAlwaysAuthorization];
        
    }
    //开始监测用户位置
    
//    self.locationManager.desiredAccuracy = kCLLocationAccuracyKilometer;
    self.locationManager.delegate = self;
    [self.locationManager startUpdatingLocation];

}
#pragma mark =======================数据请求=======================
- (void)cityDataRequest
{

    NSString *parmas = [NSString stringWithFormat:@"machineCode=0316B31D-CEAE-4C94-A3F8-F5BB581B0CE3&longitude=%f&latitude=%f&system=ios&version=4.2.6&channel=AppStore",_currentLocation.coordinate.longitude,_currentLocation.coordinate.latitude];
   
    
    
    [CFNetWork networkCitySelectRequest:parmas whileSuccess:^(id responseObject) {
        //接收热门城市的数据
        _hotCityArr = [[responseObject lastObject] valueForKey:@"hotCity"];
//        //接收到数组后刷新列表
//        [_selectCityView.BATView.tableView reloadData];

        //接收所有城市的数据
        _allCityArr = [[responseObject lastObject] valueForKey:@"positionCity"];
        //给城市排序分组的类的方法
        _cityWithSectionArr = [CFSortCity sortChinesePinyinWithArr:_allCityArr];
        //给城市和组名的数组分别赋值
        _sortAllCityArr = [_cityWithSectionArr firstObject];
        _sectionNameArr = [_cityWithSectionArr lastObject];
        //接收到数组后刷新列表
        [_selectCityView.tableView reloadData];


    } orFail:^(id responseObject) {
        NSLog(@"数据请求失败");
    }];

}


#pragma mark =======================代理方法=======================
#pragma mark- CLLocationManagerDelegate
//定位成功，返回位置信息
-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    
    _currentLocation = locations[0];
    NSLog(@"%@",_currentLocation);
    [_locationManager stopUpdatingLocation];
    // 3.根据CLLocation对象获取对应的地标信息
    [self.geocoder reverseGeocodeLocation:_currentLocation completionHandler:^(NSArray *placemarks, NSError *error) {
        
        for (CLPlacemark *placemark in placemarks) {
            _cityName = placemark.locality;
        }
       //刷新列表
        [_selectCityView.tableView reloadData];
    }];
    

    
}
//定位失败
-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
    
    NSLog(@"定位失败");
    
}
#pragma mark - 搜索框代理方法
/**
 *  键盘弹出:搜索框开始编辑文字
 */
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{

    // 2.显示遮盖

    [UIView animateWithDuration:0.5 animations:^{
        _cover.alpha = 0.5;
    }];
    // 3.显示搜索框右边的取消按钮
    [searchBar setShowsCancelButton:YES animated:YES];
    [_cover addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:searchBar action:@selector(resignFirstResponder)]];

    [_cover mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_selectCityView.tableView.mas_left);
        make.right.equalTo(_selectCityView.tableView.mas_right);
        make.top.equalTo(_selectCityView.tableView.mas_top);
        make.bottom.equalTo(_selectCityView.tableView.mas_bottom);
    }];
    
    // 3.修改搜索框的背景图片
    [searchBar setBackgroundImage:[UIImage imageNamed:@"bg_login_textfield_hl"]];

}

/**
 *  键盘退下:搜索框结束编辑文字
 */
- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    // 1.隐藏取消按钮
    [searchBar setShowsCancelButton:NO animated:YES];
    // 2.隐藏遮盖]
    [UIView animateWithDuration:0.5 animations:^{
        _cover.alpha = 0;
    }];
    
    
    // 3.修改搜索框的背景图片
    [searchBar setBackgroundImage:[UIImage imageNamed:@"bg_login_textfield"]];
    
    // 4.移除搜索结果
    self.citySearchResult.view.hidden = YES;
    searchBar.text = nil;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
}
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if (searchText.length)
    {
        self.citySearchResult.view.hidden = NO;
        [self.cover bringSubviewToFront:self.citySearchResult.view];
        self.citySearchResult.searchText = searchText;
    }
    else
    {
        self.citySearchResult.view.hidden = YES;
    }
}
#pragma mark- UITableViewDelegate
//返回索引的title
//- (NSArray *) sectionIndexTitlesForTableView:(UITableView *)tableView
//{
//    return _sectionIndexArr;
//}

//返回组数
- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {

    return _sortAllCityArr.count+3;
}
//返回tableView的每组行数
- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0||section == 1||section == 2) {
        return 1;
    }
    else
    {
        //城市列表在这一组显示,显示行数
        //数组index从0开始,所以减3
        NSArray *arr = _sortAllCityArr[section-3];
        return arr.count;

    }
}
//返回行高
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1) {
         NSMutableArray *historyCityArr = [CFShareInstance shareInstance];
        if (historyCityArr.count/3.0f <=1) {
            return 35;
        }
        return 70;
    }
    if (indexPath.section == 2) {
        return _hotCityArr.count/3 * 35;
    }
    return 35;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        CFCurrentLocationTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell_1" forIndexPath:indexPath];
        cell.currentCityLabel.text = _cityName;
        cell.textLabel.textColor = CFColor(55, 55, 55);
        NSLog(@"%@",_cityName);
        return cell;
    }
    if (indexPath.section == 1) {
        CFHistoryCityViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"cell_3"];
        NSMutableArray *historyCityArr = [CFShareInstance shareInstance];
        [cell fillItemWithModel:historyCityArr];
        return cell;

    }
    if (indexPath.section == 2) {
        CFHotCityTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell_2" forIndexPath:indexPath];
        [cell fillItemWithModel:_hotCityArr];
        return cell;
    }
    else
    {
        
        //城市列表在这一组显示
        UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
        //数组index从0开始,所以减3
        cell.textLabel.text = _sortAllCityArr[indexPath.section-3][indexPath.row][@"cityNameAbbr"];
        cell.textLabel.font = [UIFont systemFontOfSize:15];
        cell.textLabel.textColor = CFColor(55, 55, 55);

        return cell;
    }

    
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return 0;
    }
    return 25;
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *headerView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, IphoneWidth, 25)];
    headerView.backgroundColor = CFColor(241, 242, 245);
    
    UILabel *sectionNameLabel = [[UILabel alloc]initWithFrame:CGRectMake(15, 0, IphoneWidth-15, 25)];
    sectionNameLabel.font = [UIFont systemFontOfSize:12];
    sectionNameLabel.textColor = [UIColor grayColor];
    [headerView addSubview:sectionNameLabel];
    if (section == 0)
    {
        return headerView;
    }
    if (section == 1)
    {
        sectionNameLabel.text = @"历史记录";
        return headerView;

    }
    if (section == 2)
    {
        sectionNameLabel.text = @"热门城市";
        return headerView;
    }

    else
    {
        sectionNameLabel.font = [UIFont boldSystemFontOfSize:14];
        sectionNameLabel.text = _sectionNameArr[section-3];
        return headerView;
    }
    
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    //点击这一行的数据(字典)
    _cityInfodic = _sortAllCityArr[indexPath.section-3][indexPath.row];
    //当点击的时候将点击的数据传入历史记录
    NSMutableArray *historyCityArr = [CFShareInstance shareInstance];
    if (historyCityArr.count<6) {
        [historyCityArr addObject:_cityInfodic];
    }
    else
    {
        [historyCityArr removeLastObject];//移除最后一个字典
        [historyCityArr addObject:_cityInfodic];//加入新的字典

    }
    //将cityCode存入到本地
    [[NSUserDefaults standardUserDefaults]setValue:_cityInfodic[@"cityCode"] forKey:@"cityCode"];
    [[NSUserDefaults standardUserDefaults]synchronize];
    //通知中心
    [[NSNotificationCenter defaultCenter] postNotificationName:CFCityDidChangeNotification object:nil userInfo:@{CFSelectCityDic:_cityInfodic}];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark MJNIndexView代理方法

- (NSArray *)sectionIndexTitlesForMJNIndexView:(MJNIndexView *)indexView
{
    return _sectionIndexArr;
}

- (void)sectionForSectionMJNIndexTitle:(NSString *)title atIndex:(NSInteger)index;
{
    [_selectCityView.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForItem:0  inSection:index] atScrollPosition: UITableViewScrollPositionTop     animated:YES];
}
@end
