//
//  ViewController.m
//  iSH
//
//  Created by Theodore Dubois on 10/17/17.
//

#import "TerminalViewController.h"
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
@property int sessionPid;

@property (nonatomic) Terminal *terminal;
@property (nonatomic) Terminal *sessionTerminal;

@end

static void ios_handle_exit(struct task *task, int code) {
    // we are interested in init and in children of init
    // this is called with pids_lock as an implementation side effect, please do not cite as an example of good API design
//    if (task->parent != NULL && task->parent->parent != NULL)
//        return;
//    // pid should be saved now since task would be freed
//    pid_t pid = task->pid;
//    dispatch_async(dispatch_get_main_queue(), ^{
//        [[NSNotificationCenter defaultCenter] postNotificationName:ProcessExitedNotification
//                                                            object:nil
//                                                          userInfo:@{@"pid": @(pid),
//                                                                     @"code": @(code)}];
//    });
}

// Put the abort message in the thread name so it gets included in the crash dump
static void ios_handle_die(const char *msg) {
    char name[17];
    pthread_getname_np(pthread_self(), name, sizeof(name));
    NSString *newName = [NSString stringWithFormat:@"%s died: %s", name, msg];
    pthread_setname_np(newName.UTF8String);
}

//static NSString *const kSkipStartupMessage = @"Skip Startup Message";

static NSURL *RootsDir2() {
    static NSURL *rootsDir;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        rootsDir = [[NSFileManager.defaultManager containerURLForSecurityApplicationGroupIdentifier:@"group.app.ish.iSH"] URLByAppendingPathComponent:@"roots"];
        NSFileManager *manager = [NSFileManager defaultManager];
        [manager createDirectoryAtURL:rootsDir
          withIntermediateDirectories:YES
                           attributes:@{}
                                error:nil];
    });
    return rootsDir;
}

@implementation TerminalViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self boot];
    
    
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
    
    [self startSession];
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

- (int)boot {
    NSURL *root = [RootsDir2() URLByAppendingPathComponent:[NSUserDefaults.standardUserDefaults stringForKey:@"Default Root"]];
    
    NSLog(@"root: %@", root);

    int err = mount_root(&fakefs, [root URLByAppendingPathComponent:@"data"].fileSystemRepresentation);
    if (err < 0)
        return err;

//    fs_register(&iosfs);
//    fs_register(&iosfs_unsafe);

    // need to do this first so that we can have a valid current for the generic_mknod calls
    err = become_first_process();
    if (err < 0)
        return err;

//    FsInitialize();

    // create some device nodes
    // this will do nothing if they already exist
    generic_mknodat(AT_PWD, "/dev/tty1", S_IFCHR|0666, dev_make(TTY_CONSOLE_MAJOR, 1));
    generic_mknodat(AT_PWD, "/dev/tty2", S_IFCHR|0666, dev_make(TTY_CONSOLE_MAJOR, 2));
    generic_mknodat(AT_PWD, "/dev/tty3", S_IFCHR|0666, dev_make(TTY_CONSOLE_MAJOR, 3));
    generic_mknodat(AT_PWD, "/dev/tty4", S_IFCHR|0666, dev_make(TTY_CONSOLE_MAJOR, 4));
    generic_mknodat(AT_PWD, "/dev/tty5", S_IFCHR|0666, dev_make(TTY_CONSOLE_MAJOR, 5));
    generic_mknodat(AT_PWD, "/dev/tty6", S_IFCHR|0666, dev_make(TTY_CONSOLE_MAJOR, 6));
    generic_mknodat(AT_PWD, "/dev/tty7", S_IFCHR|0666, dev_make(TTY_CONSOLE_MAJOR, 7));

    generic_mknodat(AT_PWD, "/dev/tty", S_IFCHR|0666, dev_make(TTY_ALTERNATE_MAJOR, DEV_TTY_MINOR));
    generic_mknodat(AT_PWD, "/dev/console", S_IFCHR|0666, dev_make(TTY_ALTERNATE_MAJOR, DEV_CONSOLE_MINOR));
    generic_mknodat(AT_PWD, "/dev/ptmx", S_IFCHR|0666, dev_make(TTY_ALTERNATE_MAJOR, DEV_PTMX_MINOR));

    generic_mknodat(AT_PWD, "/dev/null", S_IFCHR|0666, dev_make(MEM_MAJOR, DEV_NULL_MINOR));
    generic_mknodat(AT_PWD, "/dev/zero", S_IFCHR|0666, dev_make(MEM_MAJOR, DEV_ZERO_MINOR));
    generic_mknodat(AT_PWD, "/dev/full", S_IFCHR|0666, dev_make(MEM_MAJOR, DEV_FULL_MINOR));
    generic_mknodat(AT_PWD, "/dev/random", S_IFCHR|0666, dev_make(MEM_MAJOR, DEV_RANDOM_MINOR));
    generic_mknodat(AT_PWD, "/dev/urandom", S_IFCHR|0666, dev_make(MEM_MAJOR, DEV_URANDOM_MINOR));
    
    generic_mkdirat(AT_PWD, "/dev/pts", 0755);
    
    // Permissions on / have been broken for a while, let's fix them
    generic_setattrat(AT_PWD, "/", (struct attr) {.type = attr_mode, .mode = 0755}, false);
    
    // Register clipboard device driver and create device node for it
//    err = dyn_dev_register(&clipboard_dev, DEV_CHAR, DYN_DEV_MAJOR, DEV_CLIPBOARD_MINOR);
//    if (err != 0) {
//        return err;
//    }
//    generic_mknodat(AT_PWD, "/dev/clipboard", S_IFCHR|0666, dev_make(DYN_DEV_MAJOR, DEV_CLIPBOARD_MINOR));
    
    err = dyn_dev_register(&location_dev, DEV_CHAR, DYN_DEV_MAJOR, DEV_LOCATION_MINOR);
    if (err != 0)
        return err;
    generic_mknodat(AT_PWD, "/dev/location", S_IFCHR|0666, dev_make(DYN_DEV_MAJOR, DEV_LOCATION_MINOR));

    do_mount(&procfs, "proc", "/proc", "", 0);
    do_mount(&devptsfs, "devpts", "/dev/pts", "", 0);

//    iosfs_init(); // let it mount any filesystems from user defaults

    [self configureDns];
    
    exit_hook = ios_handle_exit;
    die_handler = ios_handle_die;
#if !TARGET_OS_SIMULATOR
    NSString *sockTmp = [NSTemporaryDirectory() stringByAppendingString:@"ishsock"];
    sock_tmp_prefix = strdup(sockTmp.UTF8String);
#endif
    
    tty_drivers[TTY_CONSOLE_MAJOR] = &ios_console_driver;
    set_console_device(TTY_CONSOLE_MAJOR, 1);
    err = create_stdio("/dev/console", TTY_CONSOLE_MAJOR, 1);
    if (err < 0)
        return err;
    
    NSArray<NSString *> *command;
    NSMutableArray<NSString *> *command1 = [NSMutableArray<NSString *> new];
    command1[0] = @"/bin/login";
    command1[1] = @"-f";
    command1[2] = @"root";
    command = command1;
    
    NSLog(@"%@", command);
    char argv[4096];
    [Terminal convertCommand:command toArgs:argv limitSize:sizeof(argv)];
    const char *envp = "TERM=xterm-256color\0";
    err = do_execve("/bin/login", 3, argv, envp);
    if (err < 0)
        return err;
    task_start(current);
    
    return 0;
}

- (void)configureDns {
    struct __res_state res;
    if (EXIT_SUCCESS != res_ninit(&res)) {
        exit(2);
    }
    NSMutableString *resolvConf = [NSMutableString new];
    if (res.dnsrch[0] != NULL) {
        [resolvConf appendString:@"search"];
        for (int i = 0; res.dnsrch[i] != NULL; i++) {
            [resolvConf appendFormat:@" %s", res.dnsrch[i]];
        }
        [resolvConf appendString:@"\n"];
    }
    union res_sockaddr_union servers[NI_MAXSERV];
    int serversFound = res_getservers(&res, servers, NI_MAXSERV);
    char address[NI_MAXHOST];
    for (int i = 0; i < serversFound; i ++) {
        union res_sockaddr_union s = servers[i];
        if (s.sin.sin_len == 0)
            continue;
        getnameinfo((struct sockaddr *) &s.sin, s.sin.sin_len,
                    address, sizeof(address),
                    NULL, 0, NI_NUMERICHOST);
        [resolvConf appendFormat:@"nameserver %s\n", address];
    }
    
    current = pid_get_task(1);
    struct fd *fd = generic_open("/etc/resolv.conf", O_WRONLY_ | O_CREAT_ | O_TRUNC_, 0666);
    if (!IS_ERR(fd)) {
        fd->ops->write(fd, resolvConf.UTF8String, [resolvConf lengthOfBytesUsingEncoding:NSUTF8StringEncoding]);
        fd_close(fd);
    }
}

#pragma mark Bar

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

- (void)setTerminal:(Terminal *)terminal {
//    NSString *sourceString = [[NSThread callStackSymbols] objectAtIndex:1];
//    NSCharacterSet *separatorSet = [NSCharacterSet characterSetWithCharactersInString:@" -[]+?.,"];
//    NSMutableArray *array = [NSMutableArray arrayWithArray:[sourceString  componentsSeparatedByCharactersInSet:separatorSet]];
//    [array removeObject:@""];
//    NSLog(@"Stack = %@", [array objectAtIndex:0]);
//    NSLog(@"Framework = %@", [array objectAtIndex:1]);
//    NSLog(@"Memory address = %@", [array objectAtIndex:2]);
//    NSLog(@"Class caller = %@", [array objectAtIndex:3]);
//    NSLog(@"Function caller = %@", [array objectAtIndex:4]);

    
    
    _terminal = terminal;
    self.terminalView.terminal = self.terminal;
}

- (void)setSessionTerminal:(Terminal *)sessionTerminal {
//    NSString *sourceString = [[NSThread callStackSymbols] objectAtIndex:1];
//    NSCharacterSet *separatorSet = [NSCharacterSet characterSetWithCharactersInString:@" -[]+?.,"];
//    NSMutableArray *array = [NSMutableArray arrayWithArray:[sourceString  componentsSeparatedByCharactersInSet:separatorSet]];
//    [array removeObject:@""];
//    NSLog(@"Stack = %@", [array objectAtIndex:0]);
//    NSLog(@"Framework = %@", [array objectAtIndex:1]);
//    NSLog(@"Memory address = %@", [array objectAtIndex:2]);
//    NSLog(@"Class caller = %@", [array objectAtIndex:3]);
//    NSLog(@"Function caller = %@", [array objectAtIndex:4]);
    
    
    if (_terminal == _sessionTerminal)
        self.terminal = sessionTerminal;
    _sessionTerminal = sessionTerminal;
}

//- (void)setTerminal:(Terminal *)terminal {
//    self.terminal = terminal;
//    self.terminalView.terminal = self.terminal;
//}
//
//- (void)setSessionTerminal:(Terminal *)sessionTerminal {
//    if (self.terminal == self.sessionTerminal)
//        self.terminal = sessionTerminal;
//    self.sessionTerminal = sessionTerminal;
//}

@end
