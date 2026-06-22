#import "MainViewController.h"

#include <stdio.h>
#include <string.h>
#include <unistd.h>

@import ConsoleDock;
@import ConsoleDockCore;

static void SampleAppLogInfo(NSString *message)
{
    NSString *formattedMessage = [NSString stringWithFormat:@"[sample app logger] %@", message];
    NSLog(@"%@", formattedMessage);
    [CDKConsoleDock info:formattedMessage];
}

static NSString *const SampleAccessibilityStatusIdentifier = @"objc-sample.status";

static NSString *SampleAccessibilityButtonIdentifier(NSString *title)
{
    NSCharacterSet *separatorSet = [[NSCharacterSet alphanumericCharacterSet] invertedSet];
    NSArray<NSString *> *rawComponents = [title.lowercaseString componentsSeparatedByCharactersInSet:separatorSet];
    NSMutableArray<NSString *> *components = [NSMutableArray array];
    for (NSString *component in rawComponents) {
        if (component.length > 0) {
            [components addObject:component];
        }
    }
    return [@"objc-sample." stringByAppendingString:[components componentsJoinedByString:@"-"]];
}

@interface MainViewController ()

@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic) NSInteger counter;

@end

@implementation MainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"ConsoleDock ObjC";
    self.view.backgroundColor = [UIColor colorWithWhite:0.96 alpha:1.0];
    [self configureView];
    [self updateStatus:@"ConsoleDock started. Tap CD or Show Console."];
}

- (void)configureView
{
    UILabel *headingLabel = [[UILabel alloc] init];
    headingLabel.text = @"ConsoleDock Objective-C Sample";
    headingLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle2];
    headingLabel.textColor = UIColor.blackColor;
    headingLabel.numberOfLines = 0;

    UILabel *bodyLabel = [[UILabel alloc] init];
    bodyLabel.text = @"Generate Objective-C, C stdio, direct descriptor writes, and NSLog output, then open the in-app console.";
    bodyLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    bodyLabel.textColor = [UIColor colorWithWhite:0.25 alpha:1.0];
    bodyLabel.numberOfLines = 0;

    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    self.statusLabel.textColor = [UIColor colorWithWhite:0.28 alpha:1.0];
    self.statusLabel.numberOfLines = 0;
    self.statusLabel.accessibilityIdentifier = SampleAccessibilityStatusIdentifier;

    UIStackView *stackView = [[UIStackView alloc] initWithArrangedSubviews:@[
        headingLabel,
        bodyLabel,
        [self makeButtonWithTitle:@"Show Console" action:@selector(showConsole)],
        [self makeButtonWithTitle:@"Log diagnostics" action:@selector(logDiagnostics)],
        [self makeButtonWithTitle:@"App logger sink" action:@selector(logAppLoggerSink)],
        [self makeButtonWithTitle:@"CDKConsoleDock info" action:@selector(logNativeInfo)],
        [self makeButtonWithTitle:@"CDKConsoleDock error" action:@selector(logNativeError)],
        [self makeButtonWithTitle:@"CDKConsoleDock fault" action:@selector(logNativeFault)],
        [self makeButtonWithTitle:@"printf stdout" action:@selector(logPrintf)],
        [self makeButtonWithTitle:@"fprintf stderr" action:@selector(logStderr)],
        [self makeButtonWithTitle:@"write stdout" action:@selector(logWriteStdout)],
        [self makeButtonWithTitle:@"write stderr" action:@selector(logWriteStderr)],
        [self makeButtonWithTitle:@"NSLog" action:@selector(logNSLog)],
        [self makeButtonWithTitle:@"Clear ConsoleDock Entries" action:@selector(clearEntries)],
        [self makeButtonWithTitle:@"Stop ConsoleDock" action:@selector(stopConsoleDock)],
        [self makeButtonWithTitle:@"Start ConsoleDock" action:@selector(startConsoleDock)],
        self.statusLabel
    ]];
    stackView.translatesAutoresizingMaskIntoConstraints = NO;
    stackView.axis = UILayoutConstraintAxisVertical;
    stackView.alignment = UIStackViewAlignmentFill;
    stackView.spacing = 12;

    UIScrollView *scrollView = [[UIScrollView alloc] init];
    scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    scrollView.alwaysBounceVertical = YES;
    [scrollView addSubview:stackView];
    [self.view addSubview:scrollView];

    UILayoutGuide *safeArea = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [scrollView.leadingAnchor constraintEqualToAnchor:safeArea.leadingAnchor],
        [scrollView.trailingAnchor constraintEqualToAnchor:safeArea.trailingAnchor],
        [scrollView.topAnchor constraintEqualToAnchor:safeArea.topAnchor],
        [scrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        [stackView.leadingAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.leadingAnchor constant:20],
        [stackView.trailingAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.trailingAnchor constant:-20],
        [stackView.topAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.topAnchor constant:24],
        [stackView.bottomAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.bottomAnchor constant:-24],
        [stackView.widthAnchor constraintEqualToAnchor:scrollView.frameLayoutGuide.widthAnchor constant:-40]
    ]];
}

- (UIButton *)makeButtonWithTitle:(NSString *)title action:(SEL)action
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:title forState:UIControlStateNormal];
    button.accessibilityIdentifier = SampleAccessibilityButtonIdentifier(title);
    button.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    button.titleLabel.adjustsFontForContentSizeCategory = YES;
    button.backgroundColor = UIColor.whiteColor;
    button.layer.borderColor = [UIColor colorWithWhite:0.78 alpha:1.0].CGColor;
    button.layer.borderWidth = 1;
    button.layer.cornerRadius = 8;
    button.contentEdgeInsets = UIEdgeInsetsMake(12, 14, 12, 14);
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (NSString *)nextMessageWithPrefix:(NSString *)prefix
{
    self.counter += 1;
    return [NSString stringWithFormat:@"%@ #%ld token=objc-secret-%ld",
                                      prefix,
                                      (long)self.counter,
                                      (long)self.counter];
}

- (void)updateStatus:(NSString *)message
{
    CDKDiagnostics *diagnostics = [CDKConsoleDock diagnostics];
    self.statusLabel.text = [NSString stringWithFormat:@"%@\nRunning: %@  Stored entries: %lu  "
                                                       @"stdout: %@  stderr: %@",
                                                       message,
                                                       diagnostics.isRunning ? @"YES" : @"NO",
                                                       (unsigned long)diagnostics.entryCount,
                                                       diagnostics.captureStandardOutput ? @"YES" : @"NO",
                                                       diagnostics.captureStandardError ? @"YES" : @"NO"];
}

- (void)updateStatusAfterCapture:(NSString *)message
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self updateStatus:message];
    });
}

- (void)showConsole
{
    [CDKConsoleDockUIKit showConsole];
    [self updateStatus:@"Requested ConsoleDock panel."];
}

- (void)logDiagnostics
{
    CDKDiagnostics *diagnostics = [CDKConsoleDock diagnostics];
    NSString *message = [NSString stringWithFormat:@"objc diagnostics running=%@ entries=%lu "
                                                   @"stdout=%@ stderr=%@ limits=%lu/%lu "
                                                   @"redacted=%lu truncated=%lu partial=%lu",
                                                   diagnostics.isRunning ? @"YES" : @"NO",
                                                   (unsigned long)diagnostics.entryCount,
                                                   diagnostics.captureStandardOutput ? @"YES" : @"NO",
                                                   diagnostics.captureStandardError ? @"YES" : @"NO",
                                                   (unsigned long)diagnostics.maximumEntries,
                                                   (unsigned long)diagnostics.maximumMessageLength,
                                                   (unsigned long)diagnostics.redactedEntryCount,
                                                   (unsigned long)diagnostics.truncatedEntryCount,
                                                   (unsigned long)diagnostics.partialEntryCount];
    [CDKConsoleDock info:message];
    [self updateStatus:@"Wrote ConsoleDock diagnostics."];
}

- (void)logAppLoggerSink
{
    SampleAppLogInfo([self nextMessageWithPrefix:@"objc app logger sink"]);
    [self updateStatusAfterCapture:@"Wrote app logger sink."];
}

- (void)logNativeInfo
{
    NSString *message = [self nextMessageWithPrefix:@"objc native info"];
    [CDKConsoleDock info:message];
    [self updateStatus:@"Wrote CDKConsoleDock info."];
}

- (void)logNativeError
{
    NSString *message = [self nextMessageWithPrefix:@"objc native error"];
    [CDKConsoleDock error:message];
    [self updateStatus:@"Wrote CDKConsoleDock error."];
}

- (void)logNativeFault
{
    NSString *message = [self nextMessageWithPrefix:@"objc native fault"];
    [CDKConsoleDock fault:message];
    [self updateStatus:@"Wrote CDKConsoleDock fault."];
}

- (void)logPrintf
{
    NSString *message = [self nextMessageWithPrefix:@"objc printf stdout"];
    printf("%s\n", message.UTF8String);
    fflush(stdout);
    [self updateStatusAfterCapture:@"Wrote printf stdout."];
}

- (void)logStderr
{
    NSString *message = [self nextMessageWithPrefix:@"objc fprintf stderr"];
    fprintf(stderr, "%s\n", message.UTF8String);
    fflush(stderr);
    [self updateStatusAfterCapture:@"Wrote fprintf stderr."];
}

- (void)logWriteStdout
{
    NSString *message = [[self nextMessageWithPrefix:@"objc write stdout"] stringByAppendingString:@"\n"];
    const char *bytes = message.UTF8String;
    write(STDOUT_FILENO, bytes, strlen(bytes));
    [self updateStatusAfterCapture:@"Wrote direct stdout."];
}

- (void)logWriteStderr
{
    NSString *message = [[self nextMessageWithPrefix:@"objc write stderr"] stringByAppendingString:@"\n"];
    const char *bytes = message.UTF8String;
    write(STDERR_FILENO, bytes, strlen(bytes));
    [self updateStatusAfterCapture:@"Wrote direct stderr."];
}

- (void)logNSLog
{
    NSLog(@"%@", [self nextMessageWithPrefix:@"objc NSLog output"]);
    [self updateStatusAfterCapture:@"Wrote NSLog."];
}

- (void)clearEntries
{
    [CDKConsoleDock clearEntries];
    [self updateStatus:@"Cleared ConsoleDock entries."];
}

- (void)stopConsoleDock
{
    [CDKConsoleDockUIKit stop];
    [self updateStatus:@"Stopped ConsoleDock."];
}

- (void)startConsoleDock
{
    CDKConfiguration *configuration = [CDKConfiguration defaultConfiguration];
    configuration.maximumEntries = 500;
    configuration.maximumMessageLength = 4096;
    configuration.captureStandardOutput = YES;
    configuration.captureStandardError = YES;
    configuration.showsFloatingButton = YES;
    configuration.allowsReleaseBuilds = NO;

    NSError *error = nil;
    CDKStartResult result = [CDKConsoleDockUIKit startWithConfiguration:configuration error:&error];
    if (result == CDKStartResultFailed) {
        [self updateStatus:[NSString stringWithFormat:@"Failed to start ConsoleDock: %@",
                                                      error.localizedDescription ?: @"Unknown error"]];
        return;
    }

    [self updateStatus:@"Started ConsoleDock."];
}

@end
