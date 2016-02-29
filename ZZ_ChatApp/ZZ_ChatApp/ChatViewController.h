//
//  ChatViewController.h
//  ZZ_ChatApp
//
//  Created by lanou3g on 16/2/26.
//  Copyright © 2016年 张泽. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XMPPManager.h"
@interface ChatViewController : UIViewController

//聊天好友的 Jid
@property(nonatomic,strong)XMPPJID *friendJid;
@end
