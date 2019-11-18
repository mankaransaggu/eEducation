//
//  MainViewController.m
//  AgoraSmallClass
//
//  Created by yangmoumou on 2019/5/9.
//  Copyright © 2019 yangmoumou. All rights reserved.
//

#import "MainViewController.h"
#import "AgoraHttpRequest.h"
#import "RoomViewController.h"
#import "RoomUserModel.h"
#import "ClassRoomDataManager.h"
#import "NetworkViewController.h"
#import "EyeCareModeUtil.h"
#import "SettingViewController.h"
#import "BCViewController.h"
#import "EEClassRoomTypeView.h"
#import "OneToOneViewController.h"
#import <Foundation/Foundation.h>
#import "EEPublicMethodsManager.h"
#import "MCViewController.h"

@interface MainViewController ()<AgoraRtmDelegate,AgoraRtmChannelDelegate,ClassRoomDataManagerDelegate,EEClassRoomTypeDelegate,UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UIView *baseView;
@property (weak, nonatomic) IBOutlet UITextField *classNameTextFiled;
@property (weak, nonatomic) IBOutlet UITextField *userNameTextFiled;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textViewBottomCon;
@property (nonatomic, strong) AgoraRtmKit *agoraRtmKit;
@property (nonatomic, strong) AgoraRtmChannel *agoraRtmChannel;
@property (nonatomic, copy)   NSString *serverRtmId;
@property (nonatomic, strong) UIActivityIndicatorView * activityIndicator;
@property (nonatomic, copy)   NSString  *className;
@property (nonatomic, copy)   NSString *userName;
@property (nonatomic, assign) ClassRoomRole classRoomRole;
@property (nonatomic, copy)   NSString *uid;
@property (nonatomic, strong) NSMutableArray *userArray;
@property (nonatomic, strong) ClassRoomDataManager *roomDataManager;
@property (nonatomic, weak) EEClassRoomTypeView *classRoomTypeView;
@property (weak, nonatomic) IBOutlet UIButton *roomType;
@property (nonatomic, assign) AgoraRtmConnectionState rtmConnectionState;
@end

@implementation MainViewController
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.roomDataManager.classRoomManagerDelegate = self;
    if ([[EyeCareModeUtil sharedUtil] queryEyeCareModeStatus]) {
        [[EyeCareModeUtil sharedUtil] switchEyeCareMode:YES];
    }
}
- (void)viewWillAppear:(BOOL)animated {
    self.navigationController.navigationBarHidden = YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.roomDataManager = [ClassRoomDataManager shareManager];
    self.uid = [self getUserID];
    self.roomDataManager.uid = self.uid;
    [self joinRtm];
    [self setUpView];
    [self addTouchedRecognizer];
    [self addKeyboardNotification];
}

- (void)setUpView {
    self.activityIndicator = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:(UIActivityIndicatorViewStyleWhiteLarge)];
    [self.view addSubview:self.activityIndicator];
    self.activityIndicator.frame= CGRectMake((kScreenWidth -100)/2, (kScreenHeight - 100)/2, 100, 100);
    self.activityIndicator.color = [UIColor grayColor];
    self.activityIndicator.backgroundColor = [UIColor whiteColor];
    self.activityIndicator.hidesWhenStopped = YES;

    self.classRoomRole = ClassRoomRoleStudent;
    self.roomDataManager.roomRole = ClassRoomRoleStudent;

    EEClassRoomTypeView *classRoomTypeView = [EEClassRoomTypeView initWithXib:CGRectMake(30, kScreenHeight - 300, kScreenWidth - 60, 150)];
    [self.view addSubview:classRoomTypeView];
    self.classRoomTypeView = classRoomTypeView;
    classRoomTypeView.hidden = YES;
    classRoomTypeView.delegate = self;
}

- (void)addTouchedRecognizer {
    UITapGestureRecognizer *touchedControl = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(touchedBegan:)];
    [self.baseView addGestureRecognizer:touchedControl];
}

- (void)addKeyboardNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShow:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeHiden:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)joinRtm {
    self.agoraRtmKit = [[AgoraRtmKit alloc] initWithAppId:kAgoraAppid delegate:self];
    WEAK(self)
    [self.agoraRtmKit loginByToken:nil user:self.uid completion:^(AgoraRtmLoginErrorCode errorCode) {
        if (errorCode == AgoraRtmLoginErrorOk) {
            weakself.roomDataManager.agoraRtmKit = weakself.agoraRtmKit;
        }
    }];
}

- (void)joinRtmChannelCompletion:(AgoraRtmJoinChannelBlock _Nullable)completionBlock {
    self.agoraRtmChannel  =  [self.agoraRtmKit createChannelWithId:self.className delegate:self];
    [self.agoraRtmChannel joinWithCompletion:completionBlock];
    self.roomDataManager.agoraRtmChannel = self.agoraRtmChannel;
}

- (void)keyboardWasShow:(NSNotification *)notification {
    CGRect frame = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    float bottom = frame.size.height;
    self.textViewBottomCon.constant = bottom;
}

- (void)keyboardWillBeHiden:(NSNotification *)notification {
    self.textViewBottomCon.constant = 261;
}

- (void)touchedBegan:(UIGestureRecognizer *)recognizer {
    [self.classNameTextFiled resignFirstResponder];
    [self.userNameTextFiled resignFirstResponder];
    self.classRoomTypeView.hidden  = YES;
}

- (void)setButtonStyle:(UIButton *)button {
    if (button.selected == YES) {
        [button setBackgroundColor:RCColorWithValue(0x006EDE, 1)];
        [button setTitleColor:[UIColor whiteColor] forState:(UIControlStateNormal)];
        [button.titleLabel setFont:[UIFont fontWithName:@"Helvetica Neue" size:16]];

    }else {
        [button setBackgroundColor:[UIColor whiteColor]];
        button.layer.borderColor = RCColorWithValue(0xCCCCCC, 1).CGColor;
        button.layer.borderWidth = 1;
        [button setTitleColor:RCColorWithValue(0xCCCCCC,1) forState:(UIControlStateNormal)];
    }
}

- (NSString *)getUserID{
    NSDate *datenow = [NSDate date];
    NSString *timeSp = [NSString stringWithFormat:@"%ld", (long)([datenow timeIntervalSince1970])];
    NSString *uid =  [NSString stringWithFormat:@"2%@",[timeSp substringFromIndex:3]];
    return uid;
}

- (IBAction)popupRoomType:(UIButton *)sender {
    self.classRoomTypeView.hidden = NO;
}

- (IBAction)joinRoom:(UIButton *)sender {
    [self.activityIndicator startAnimating];
    if (self.classNameTextFiled.text.length <= 0 || self.userNameTextFiled.text.length <= 0 || ![EEPublicMethodsManager judgeClassRoomText:self.classNameTextFiled.text] || ![EEPublicMethodsManager judgeClassRoomText:self.userNameTextFiled.text]) {
        [self presentAlterViewTitile:@"请检查房间号和用户名符合规格" message:@"11位及以内的数字或者英文字符" cancelActionTitle:@"取消" confirmActionTitle:nil];
        [self.activityIndicator stopAnimating];
    }else {
        self.className = self.classNameTextFiled.text;
        self.userName = self.userNameTextFiled.text;
        self.roomDataManager.className = self.className;
        self.roomDataManager.userName = self.userName;
        if ([self.roomType.titleLabel.text isEqualToString:@"小班课"]) {
            [self getServerRtmId];
            [self joinRtmChannelCompletion:nil];
        }else if ([self.roomType.titleLabel.text isEqualToString:@"大班课"]) {
            [self presentBigClassController];
        }else if ([self.roomType.titleLabel.text isEqualToString:@"一对一"]) {
            [self presentOneToOneViewController];
        }else {
            [self presentAlterViewTitile:@"join error" message:@"请选择房间类型" cancelActionTitle:@"取消" confirmActionTitle:nil];
        }
    }
}

- (IBAction)settingAction:(UIButton *)sender {
    SettingViewController *settingVC = [[SettingViewController alloc] init];
    [self.navigationController pushViewController:settingVC animated:YES];
}

- (void)presentBigClassController {
    [self.activityIndicator stopAnimating];
    if (self.rtmConnectionState == AgoraRtmConnectionStateDisconnected) {
        [self joinRtm];
    }else {
        UIStoryboard *story = [UIStoryboard storyboardWithName:@"Room" bundle:[NSBundle mainBundle]];
        BCViewController *roomVC = [story instantiateViewControllerWithIdentifier:@"bcroom"];
        roomVC.modalPresentationStyle = UIModalPresentationFullScreen;
        NSString *rtcChannelName = [NSString stringWithFormat:@"2%@",[EEPublicMethodsManager MD5WithString:self.className]];
        roomVC.params = @{
            @"channelName": self.className,
            @"rtmKit" : self.agoraRtmKit,
            @"userName": self.userName,
            @"userId" : self.uid,
            @"rtmChannelName":rtcChannelName,
        };
        [self presentViewController:roomVC animated:YES completion:nil];
    }
}

- (void)presentMiniClassViewController {
    [self.activityIndicator stopAnimating];
    UIStoryboard *story = [UIStoryboard storyboardWithName:@"Room" bundle:[NSBundle mainBundle]];
    MCViewController *mcVC = [story instantiateViewControllerWithIdentifier:@"mcRoom"];
    mcVC.modalPresentationStyle = UIModalPresentationFullScreen;
    NSString *rtcChannelName = [NSString stringWithFormat:@"1%@",[EEPublicMethodsManager MD5WithString:self.className]];
    mcVC.params = @{
                   @"channelName": self.className,
                   @"rtmKit" : self.agoraRtmKit,
                   @"userName": self.userName,
                   @"userId" : self.uid,
                   @"rtmChannelName":rtcChannelName,
               };
    [self presentViewController:mcVC animated:YES completion:nil];
}

- (void)presentOneToOneViewController {
    NSString *rtcChannelName = [NSString stringWithFormat:@"0%@",[EEPublicMethodsManager MD5WithString:self.className]];
    WEAK(self)
    [self.agoraRtmKit getChannelMemberCount:@[rtcChannelName] completion:^(NSArray<AgoraRtmChannelMemberCount *> *channelMemberCounts, AgoraRtmChannelMemberCountErrorCode errorCode) {
        if (errorCode == AgoraRtmChannelMemberCountErrorOk && weakself.childViewControllers.count < 2) {
            UIStoryboard *story = [UIStoryboard storyboardWithName:@"Room" bundle:[NSBundle mainBundle]];
            OneToOneViewController *onetooneVC = [story instantiateViewControllerWithIdentifier:@"oneToOneRoom"];
            onetooneVC.modalPresentationStyle = UIModalPresentationFullScreen;
            onetooneVC.params = @{
                @"channelName": weakself.className,
                @"rtmKit" : weakself.agoraRtmKit,
                @"userName": weakself.userName,
                @"userId" : weakself.uid,
                @"rtmChannelName":rtcChannelName,
            };
            [weakself presentViewController:onetooneVC animated:YES completion:nil];
        }
    }];

}

- (void)joinClassRoomError {
    [self.activityIndicator stopAnimating];
    [self presentAlterViewTitile:@"join classRoom error" message:@"no network" cancelActionTitle:@"取消" confirmActionTitle:nil];
}

#pragma MARK -----------------------  AgoraRtmDelegate -------------------------
- (void)rtmKit:(AgoraRtmKit * _Nonnull)kit connectionStateChanged:(AgoraRtmConnectionState)state reason:(AgoraRtmConnectionChangeReason)reason {
    self.rtmConnectionState = state;
}

- (void)channel:(AgoraRtmChannel * _Nonnull)channel memberJoined:(AgoraRtmMember * _Nonnull)member {
    NSLog(@"%@----- %@",member.userId,member.channelId);
}

- (void)selectRoomTypeName:(NSString *)name {
    [self.roomType setTitle:name forState:(UIControlStateNormal)];
    self.classRoomTypeView.hidden = YES;
}

- (void)getServerRtmId {
    WEAK(self)
    [AgoraHttpRequest get:kGetServerRtmIdUrl params:nil success:^(id responseObj) {
        [weakself.activityIndicator stopAnimating];
        NSString * str  =[[NSString alloc] initWithData:responseObj encoding:NSUTF8StringEncoding];
        weakself.roomDataManager.serverRtmId = str;
        weakself.serverRtmId = str;
        [weakself presentMiniClassViewController];
    } failure:^(NSError *error) {
        [weakself.activityIndicator stopAnimating];
        [weakself joinClassRoomError];
    }];
}

- (void)presentAlterViewTitile:(NSString *)title message:(NSString *)message cancelActionTitle:(NSString *)cancelTitle confirmActionTitle:(NSString *)confirmTitle {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    if (cancelTitle) {
            UIAlertAction *cancel = [UIAlertAction actionWithTitle:cancelTitle style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
               }];
         [alertVC addAction:cancel];
    }
    if (confirmTitle) {
        UIAlertAction *confirm = [UIAlertAction actionWithTitle:confirmTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        }];
        [alertVC addAction:confirm];
    }
    alertVC.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self presentViewController:alertVC animated:YES completion:nil];
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

#pragma mark  --------  Mandatory landscape -------
- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}
@end
