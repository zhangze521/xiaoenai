//
//  ChatViewController.m
//  ZZ_ChatApp
//
//  Created by lanou3g on 16/2/26.
//  Copyright © 2016年 张泽. All rights reserved.
//

#import "ChatViewController.h"
#import "XMPPManager.h"
@interface ChatViewController ()<UITableViewDataSource,UITableViewDelegate,UITextFieldDelegate,XMPPStreamDelegate>//发个消息遵循最后一个协议
@property (weak, nonatomic) IBOutlet UITableView *ChatTV;
//消息输入框
@property (weak, nonatomic) IBOutlet UITextField *sendMessageTextF;
//语音图片
@property (weak, nonatomic) IBOutlet UIImageView *imgV;

//存放聊天信息
@property(nonatomic,strong)NSMutableArray *messageArray;


@end

@implementation ChatViewController


- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.title = self.friendJid.user;
    self.ChatTV.dataSource = self;
    self.ChatTV.delegate = self;
    self.imgV.image = [UIImage imageNamed:[NSString stringWithFormat:@"2.png"]];
    
    //添加代理
    [[XMPPManager shareInstance].xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];

    //self.automaticallyAdjustsScrollViewInsets = NO;//    tableView 上有空格
    
    self.messageArray = [NSMutableArray array];
    
    //查询聊天记录
    [self searchMessage];
}

#pragma mark ---------------------XMPPStreamDelegate---------------------
#pragma mark -接收到消息
-(void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message{
    NSLog(@"接收到消息");
    //查询新的聊天记录
    [self searchMessage];
}
#pragma mark -消息发送失败
-(void)xmppStream:(XMPPStream *)sender didFailToSendMessage:(XMPPMessage *)message error:(NSError *)error{
    NSLog(@"消息发送失败");
}
#pragma mark -消息发送成功
-(void)xmppStream:(XMPPStream *)sender didSendMessage:(XMPPMessage *)message{
    NSLog(@"消息发送成功");
    //查询新的聊天记录
    [self searchMessage];
    
}



#pragma mark 获取聊天信息查询
-(void)searchMessage{
    //打fetch就能出来
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"XMPPMessageArchiving_Message_CoreDataObject" inManagedObjectContext:[XMPPManager shareInstance].context];
    [fetchRequest setEntity:entity];
    // Specify criteria for filtering which objects to fetch
    //点对点,两人
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@" streamBareJidStr == %@ AND bareJidStr == %@", [XMPPManager shareInstance].xmppStream.myJID.bare,self.friendJid.bare];
    
    [fetchRequest setPredicate:predicate];
    // Specify how the fetched objects should be sorted
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp"
                                                                   ascending:YES];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];
    
    NSError *error = nil;
    NSArray *fetchedObjects = [[XMPPManager shareInstance].context executeFetchRequest:fetchRequest error:&error];
    //查询失败
    if (fetchedObjects == nil) {
        NSLog(@"查询失败:%@",error);
    }
    
    //先清空数组
    [self.messageArray removeAllObjects];
    
    //放进消息数组
    [self.messageArray addObjectsFromArray:fetchedObjects];
    
    NSIndexPath *path = [NSIndexPath indexPathForRow:self.messageArray.count-1 inSection:0];
   
    //刷新
    [self.ChatTV reloadData];
    
    //自动滑动到最后一行
    [self.ChatTV scrollToRowAtIndexPath:path atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    
    NSLog(@"********************%@*******************",self.messageArray);
}

//发送消息点击事件
- (IBAction)sendMessageBtnAction:(UIButton *)sender {
    NSLog(@"发送");
    
    //创建消息对象
    XMPPMessage *message = [XMPPMessage messageWithType:@"chat" to:self.friendJid];
    
    //将消息输入框的文字加进 body
    [message addBody:self.sendMessageTextF.text];//这应该判断为空
    
    //将消息内容发送到节点
    [[XMPPManager shareInstance].xmppStream sendElement:message];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.messageArray.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"id" forIndexPath:indexPath];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"id"];
    }
    
    XMPPMessageArchiving_Message_CoreDataObject *message = self.messageArray[indexPath.row];
    //判断
    if (message.isOutgoing) {
        //发出的消息
        cell.textLabel.textAlignment = NSTextAlignmentLeft;
        
        //**************************很重要,解决 cell 混乱.脏区域导致以前消息乱入********************************************
        cell.detailTextLabel.hidden = YES;
        cell.textLabel.hidden = NO;
        
        
        NSDateFormatter *now = [[NSDateFormatter alloc]init];
        [now setDateFormat:@"yyyy-MM-dd HH:mm:ss 我: \n"];
        NSString *time = [now stringFromDate:[NSDate date]];
        NSString *Result = [time stringByAppendingString:message.body];
        cell.textLabel.text =  Result;
        cell.textLabel.font = [UIFont systemFontOfSize:15];
        cell.textLabel.numberOfLines = 0;

        
    }else{
        //接收到的消息
        cell.detailTextLabel.textAlignment = NSTextAlignmentRight;
        
        //**************************很重要,解决 cell 混乱.脏区域导致以前消息乱入********************************************
        cell.detailTextLabel.hidden = NO;
        cell.textLabel.hidden = YES;
        
        NSDateFormatter *now = [[NSDateFormatter alloc]init];
        [now setDateFormat:@"yyyy-MM-dd HH:mm:ss  对方: \n"];
        NSString *time = [now stringFromDate:[NSDate date]];
        NSString *Result = [time stringByAppendingString:message.body];
        cell.detailTextLabel.text =  Result;
        cell.detailTextLabel.font = [UIFont systemFontOfSize:15];
        cell.detailTextLabel.numberOfLines = 0;
    }

    return cell;

}

//点击输入框键盘弹出收回
 
- (IBAction)didBegin:(UITextField *)sender {

        //键盘高度216
        
        //滑动效果（动画）
        NSTimeInterval animationDuration = 0.30f;
        [UIView beginAnimations:@ "ResizeForKeyboard"  context:nil];
        [UIView setAnimationDuration:animationDuration];
        
        //将视图的Y坐标向上移动，以使下面腾出地方用于软键盘的显示
        self.view.frame = CGRectMake(0.0f, -100.0f, self.view.frame.size.width, self.view.frame.size.height); //64-216
        
        [UIView commitAnimations];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
