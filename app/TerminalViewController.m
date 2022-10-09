//
//  ViewController.m
//  iSH
//
//  Created by Theodore Dubois on 10/17/17.
//

#import "TerminalViewController.h"
#import "TerminalView.h"
#include "kernel/init.h"
#include "kernel/calls.h"
#include "fs/devices.h"

@interface TerminalViewController ()

@property TerminalView *termView;
@property UIButton *controlKey;
@property int sessionPid;
@property (nonatomic) Terminal *sessionTerminal;

@end

@implementation TerminalViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    NSLog(@"+++++++++++++++++++++++++++++++++++++++++++++++++++   viewDidLoad");
    
    UIButton *escapeKey = [UIButton buttonWithType: UIButtonTypeSystem];
    [escapeKey setFrame: CGRectMake(0.0, 0.0, 40.0, 40.0)];
    [escapeKey setTitle: @"ESC" forState: UIControlStateNormal];
    [escapeKey setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [escapeKey setBackgroundColor: [UIColor whiteColor]];
    [escapeKey addTarget: self action: @selector(pressEscape:) forControlEvents: UIControlEventTouchUpInside];
    
    UIButton *tabKey = [UIButton buttonWithType: UIButtonTypeSystem];
    [tabKey setFrame: CGRectMake(40.0, 0.0, 40.0, 40.0)];
    [tabKey setTitle: @"TAB" forState: UIControlStateNormal];
    [tabKey setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [tabKey setBackgroundColor: [UIColor whiteColor]];
    [tabKey addTarget: self action: @selector(pressTab) forControlEvents: UIControlEventTouchUpInside];
    
    self.controlKey = [UIButton buttonWithType: UIButtonTypeSystem];
    [self.controlKey setFrame: CGRectMake(80.0, 0.0, 40.0, 40.0)];
    [self.controlKey setTitle: @"CTRL" forState: UIControlStateNormal];
    [self.controlKey setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.controlKey setBackgroundColor: [UIColor whiteColor]];
    [self.controlKey addTarget: self action: @selector(pressControl:) forControlEvents: UIControlEventTouchUpInside];
    self.termView.controlKey = self.controlKey;
    
    UIButton *leftButton = [UIButton buttonWithType: UIButtonTypeSystem];
    [leftButton setFrame: CGRectMake(120.0, 0.0, 40.0, 40.0)];
    [leftButton setTitle: @"←" forState: UIControlStateNormal];
    [leftButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [leftButton setBackgroundColor: [UIColor whiteColor]];
    [leftButton addTarget: self action: @selector(pressLeft) forControlEvents: UIControlEventTouchUpInside];
    
    UIButton *rightButton = [UIButton buttonWithType: UIButtonTypeSystem];
    [rightButton setFrame: CGRectMake(160.0, 0.0, 40.0, 40.0)];
    [rightButton setTitle: @"→" forState: UIControlStateNormal];
    [rightButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [rightButton setBackgroundColor: [UIColor whiteColor]];
    [rightButton addTarget: self action: @selector(pressRight) forControlEvents: UIControlEventTouchUpInside];
    
    UIButton *upButton = [UIButton buttonWithType: UIButtonTypeSystem];
    [upButton setFrame: CGRectMake(200.0, 0.0, 40.0, 40.0)];
    [upButton setTitle: @"↑" forState: UIControlStateNormal];
    [upButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [upButton setBackgroundColor: [UIColor whiteColor]];
    [upButton addTarget: self action: @selector(pressUp) forControlEvents: UIControlEventTouchUpInside];
    
    UIButton *downButton = [UIButton buttonWithType: UIButtonTypeSystem];
    [downButton setFrame: CGRectMake(240.0, 0.0, 40.0, 40.0)];
    [downButton setTitle: @"↓" forState: UIControlStateNormal];
    [downButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [downButton setBackgroundColor: [UIColor whiteColor]];
    [downButton addTarget: self action: @selector(pressDown) forControlEvents: UIControlEventTouchUpInside];
    
    UIButton *pasteButton = [UIButton buttonWithType: UIButtonTypeSystem];
    [pasteButton setFrame: CGRectMake(280.0, 0.0, 40.0, 40.0)];
    [pasteButton setTitle: @"🅿️" forState: UIControlStateNormal];
    [pasteButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [pasteButton setBackgroundColor: [UIColor whiteColor]];
    [pasteButton addTarget: self action: @selector(pressPaste) forControlEvents: UIControlEventTouchUpInside];
    
    UIButton *hideKeyboardButton = [UIButton buttonWithType: UIButtonTypeSystem];
    [hideKeyboardButton setFrame: CGRectMake(320.0, 0.0, 40.0, 40.0)];
    [hideKeyboardButton setTitle: @"⌨️" forState: UIControlStateNormal];
    [hideKeyboardButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [hideKeyboardButton setBackgroundColor: [UIColor whiteColor]];
    [hideKeyboardButton addTarget: self action: @selector(hideKeyboard) forControlEvents: UIControlEventTouchUpInside];
    
    UIView *kbView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, 40)];
    kbView.backgroundColor = [UIColor whiteColor];
    [kbView addSubview:escapeKey];
    [kbView addSubview:tabKey];
    [kbView addSubview:self.controlKey];
    [kbView addSubview:leftButton];
    [kbView addSubview:rightButton];
    [kbView addSubview:upButton];
    [kbView addSubview:downButton];
    [kbView addSubview:pasteButton];
    [kbView addSubview:hideKeyboardButton];

    self.termView = [[TerminalView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.termView.inputAccessoryView = kbView;
    self.termView.canBecomeFirstResponder = true;
    self.terminal = self.terminal;
    
    [self.view addSubview: self.termView];
}

- (void)startNewSession {
    int err = [self startSession];
    if (err < 0) {
        [self showMessage:@"could not start session"
                 subtitle:[NSString stringWithFormat:@"error code %d", err]];
    }
}

- (void)reconnectSessionFromTerminalUUID:(NSUUID *)uuid {
    self.sessionTerminal = [Terminal terminalWithUUID:uuid];
    if (self.sessionTerminal == nil)
        [self startNewSession];
}

- (NSUUID *)sessionTerminalUUID {
    return self.terminal.uuid;
}

- (int)startSession {
//    NSArray<NSString *> *command = UserPreferences.shared.launchCommand;
    
    NSArray<NSString *> *command = [NSArray<NSString *> new];
    NSMutableArray<NSString *> *command1 = [NSMutableArray<NSString *> new];
    command1[0] = @"/bin/login";
    command1[1] = @"-f";
    command1[2] = @"root";
    command = command1;
    
    int err = become_new_init_child();
    if (err < 0)
        return err;
    struct tty *tty;
    self.sessionTerminal = nil;
    Terminal *terminal = [Terminal createPseudoTerminal:&tty];
    if (terminal == nil) {
        NSAssert(IS_ERR(tty), @"tty should be error");
        return (int) PTR_ERR(tty);
    }
    self.sessionTerminal = terminal;
    NSString *stdioFile = [NSString stringWithFormat:@"/dev/pts/%d", tty->num];
    err = create_stdio(stdioFile.fileSystemRepresentation, TTY_PSEUDO_SLAVE_MAJOR, tty->num);
    if (err < 0)
        return err;
    tty_release(tty);
    
    char argv[4096];
    [Terminal convertCommand:command toArgs:argv limitSize:sizeof(argv)];
    const char *envp = "TERM=xterm-256color\0";
    
    err = do_execve("/bin/login", 3, argv, envp);
    if (err < 0)
        return err;
    self.sessionPid = current->pid;
    task_start(current);

    return 0;
}

//#if !ISH_LINUX
- (void)processExited:(NSNotification *)notif {
    int pid = [notif.userInfo[@"pid"] intValue];
    if (pid != self.sessionPid)
        return;
    
    [self.sessionTerminal destroy];
    // On iOS 13, there are multiple windows, so just close this one.
    if (@available(iOS 13, *)) {
        // On iPhone, destroying scenes will fail, but the error doesn't actually go to the error handler, which is really stupid. Apple doesn't fix bugs, so I'm forced to just add a check here.
        if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad && self.sceneSession != nil) {
            [UIApplication.sharedApplication requestSceneSessionDestruction:self.sceneSession options:nil errorHandler:^(NSError *error) {
                NSLog(@"scene destruction error %@", error);
                self.sceneSession = nil;
                [self processExited:notif];
            }];
            return;
        }
    }
    current = NULL; // it's been freed
    [self startNewSession];
}
//#endif

//#if ISH_LINUX
//- (void)kernelPanicked:(NSNotification *)notif {
//    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"panik" message:notif.userInfo[@"message"] preferredStyle:UIAlertControllerStyleAlert];
//    [alert addAction:[UIAlertAction actionWithTitle:@"k" style:UIAlertActionStyleDefault handler:nil]];
//    [self presentViewController:alert animated:YES completion:nil];
//}
//#endif

- (void)showMessage:(NSString *)message subtitle:(NSString *)subtitle {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:message message:subtitle preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"k"
                                                  style:UIAlertActionStyleDefault
                                                handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    });
}

#pragma mark Bar

- (void)showAbout:(id)sender {
}

- (void)hideKeyboard{
    [self.termView resignFirstResponder];
}

- (void)pressEscape:(id)sender {
    [self.termView insertText:@"\x1b"];
}
- (void)pressTab{
    [self.termView insertText:@"\t"];
}

- (void)pressControl:(id)sender {
    self.controlKey.selected = !self.controlKey.selected;
}

- (void)pressLeft{
    [self.termView insertText:[self.terminal arrow:'D']];
}

- (void)pressRight{
    [self.termView insertText:[self.terminal arrow:'C']];
}

- (void)pressUp{
    [self.termView insertText:[self.terminal arrow:'A']];
}

- (void)pressDown{
    [self.termView insertText:[self.terminal arrow:'B']];
}

- (void)pressPaste{
    NSString *string = UIPasteboard.generalPasteboard.string;
    if (string) {
        [self.termView insertText:string];
    }
}

- (void)switchTerminal:(UIKeyCommand *)sender {
    unsigned i = (unsigned) sender.input.integerValue;
    if (i == 7)
        self.terminal = self.sessionTerminal;
    else
        self.terminal = [Terminal terminalWithType:TTY_CONSOLE_MAJOR number:i];
}

- (void)setTerminal:(Terminal *)terminal {
    _terminal = terminal;
    self.termView.terminal = self.terminal;
}

- (void)setSessionTerminal:(Terminal *)sessionTerminal {
    if (_terminal == _sessionTerminal)
        self.terminal = sessionTerminal;
    _sessionTerminal = sessionTerminal;
}

@end
