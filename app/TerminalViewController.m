//
//  ViewController.m
//  iSH
//
//  Created by Theodore Dubois on 10/17/17.
//

#import "TerminalViewController.h"
#import "MyUtility.h"

#import "TerminalView.h"
#import "Terminal.h"


#include "kernel/init.h"
#include "kernel/calls.h"
#include "fs/devices.h"
#include <resolv.h>
#include <arpa/inet.h>
#include <netdb.h>
#import "LocationDevice.h"
#include "fs/dyndev.h"
#include "fs/path.h"



@interface TerminalViewController ()

@property TerminalView *terminalView;
@property UIButton *controlKey;
//@property int sessionPid;

@property (nonatomic) Terminal *terminal;

@property Terminal *xxterminal;

@end

@implementation TerminalViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setKeyboard];
    
    [MyUtility boot];
    [self startSession];
    self.terminalView.terminal = self.xxterminal;
//    [MyUtility startSession];
//    self.terminalView.terminal = myutility_terminal;
}

- (void)setKeyboard {
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
    [pasteButton setTitle: @"P" forState: UIControlStateNormal];
    [pasteButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [pasteButton setBackgroundColor: [UIColor whiteColor]];
    [pasteButton addTarget: self action: @selector(pressPaste) forControlEvents: UIControlEventTouchUpInside];
    
    UIButton *hideKeyboardButton = [UIButton buttonWithType: UIButtonTypeSystem];
    [hideKeyboardButton setFrame: CGRectMake(320.0, 0.0, 40.0, 40.0)];
    [hideKeyboardButton setTitle: @"⌨" forState: UIControlStateNormal];
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
    
    self.terminalView = [[TerminalView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.terminalView.inputAccessoryView = kbView;
    self.terminalView.canBecomeFirstResponder = true;
    [self.view addSubview: self.terminalView];
}

- (int)startSession {
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
//    Terminal *xxterminal = [Terminal createPseudoTerminal:&tty];
    self.xxterminal = [Terminal createPseudoTerminal:&tty];
    if (self.xxterminal == nil) {
        NSAssert(IS_ERR(tty), @"tty should be error");
        return (int) PTR_ERR(tty);
    }
//    self.terminalView.terminal = self.xxterminal;
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
//    self.sessionPid = current->pid;
    task_start(current);
    
    return 0;
}

- (void)hideKeyboard{
    [self.terminalView resignFirstResponder];
}

- (void)pressEscape:(id)sender {
    [self.terminalView insertText:@"\x1b"];
}
- (void)pressTab{
    [self.terminalView insertText:@"\t"];
}

- (void)pressControl:(id)sender {
    self.controlKey.selected = !self.controlKey.selected;
    self.terminalView.isControlSelected = !self.terminalView.isControlSelected;
    self.terminalView.isControlHighlighted = !self.terminalView.isControlHighlighted;
}

- (void)pressLeft{
    [self.terminalView insertText:[self.terminal arrow:'D']];
}

- (void)pressRight{
    [self.terminalView insertText:[self.terminal arrow:'C']];
}

- (void)pressUp{
    [self.terminalView insertText:[self.terminal arrow:'A']];
}

- (void)pressDown{
    [self.terminalView insertText:[self.terminal arrow:'B']];
}

- (void)pressPaste{
    NSString *string = UIPasteboard.generalPasteboard.string;
    if (string) {
        [self.terminalView insertText:string];
    }
}

//- (void)setTerminal:(Terminal *)terminal {
//    _terminal = terminal;
//    self.terminalView.terminal = self.terminal;
//}
//
//- (void)setSessionTerminal:(Terminal *)sessionTerminal {
//    if (_terminal == _sessionTerminal){
//        self.terminal = sessionTerminal;
//    }
//    _sessionTerminal = sessionTerminal;
//}

//- (void)setTerminal:(Terminal *)terminal {
//    //    NSString *sourceString = [[NSThread callStackSymbols] objectAtIndex:1];
//    //    NSCharacterSet *separatorSet = [NSCharacterSet characterSetWithCharactersInString:@" -[]+?.,"];
//    //    NSMutableArray *array = [NSMutableArray arrayWithArray:[sourceString  componentsSeparatedByCharactersInSet:separatorSet]];
//    //    [array removeObject:@""];
//    //    NSLog(@"Stack = %@", [array objectAtIndex:0]);
//    //    NSLog(@"Framework = %@", [array objectAtIndex:1]);
//    //    NSLog(@"Memory address = %@", [array objectAtIndex:2]);
//    //    NSLog(@"Class caller = %@", [array objectAtIndex:3]);
//    //    NSLog(@"Function caller = %@", [array objectAtIndex:4]);
//
//
//
//    _terminal = terminal;
//    self.terminalView.terminal = self.terminal;
//}
//
//- (void)setSessionTerminal:(Terminal *)sessionTerminal {
////    NSString *sourceString = [[NSThread callStackSymbols] objectAtIndex:1];
////    NSCharacterSet *separatorSet = [NSCharacterSet characterSetWithCharactersInString:@" -[]+?.,"];
////    NSMutableArray *array = [NSMutableArray arrayWithArray:[sourceString  componentsSeparatedByCharactersInSet:separatorSet]];
////    [array removeObject:@""];
////    NSLog(@"Stack = %@", [array objectAtIndex:0]);
////    NSLog(@"Framework = %@", [array objectAtIndex:1]);
////    NSLog(@"Memory address = %@", [array objectAtIndex:2]);
////    NSLog(@"Class caller = %@", [array objectAtIndex:3]);
////    NSLog(@"Function caller = %@", [array objectAtIndex:4]);
//
//    if (_terminal == _sessionTerminal)
//        self.terminal = sessionTerminal;
//    _sessionTerminal = sessionTerminal;
//}
@end
