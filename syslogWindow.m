#import <objc/runtime.h>
#include <dlfcn.h>
#include "syslogWindow.h"

@implementation LogWindow

-(id)init{
  self = [super initWithFrame:[UIScreen mainScreen].bounds];
  if(self){
    // Setup the window
    self.backgroundColor = [UIColor clearColor];
    self.windowLevel = UIWindowLevelStatusBar + 10000;
    self.hidden = NO;

    // Setup the label stuff
    l = [[UITextView alloc] initWithFrame:CGRectMake(0,0,320,150)];
    l.textAlignment = NSTextAlignmentLeft;
    l.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.75f];
    l.textColor = [UIColor whiteColor];
    l.contentSize = l.bounds.size;
    l.clipsToBounds = YES;
    l.contentInset = UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0);
    l.textContainer.lineFragmentPadding = 0;
    l.textContainerInset = UIEdgeInsetsZero;

    [self addSubview:l];

    [self initActivatorListener];

    // And others
    msgs = [[NSMutableArray alloc] init];
  }
  return self;
}

#define LINE_REGEX "(\\w+\\s+\\d+\\s+\\d+:\\d+:\\d+)\\s+(\\S+|)\\s+(\\w+)\\[(\\d+)\\]\\s+\\<(\\w+)\\>:\\s(.*)"
-(void)addSyslogMessage:(NSString*)message{

NSError *error = nil;
  NSRegularExpression *regex = [NSRegularExpression
                                  regularExpressionWithPattern:@LINE_REGEX
                                  options:NSRegularExpressionCaseInsensitive
                                  error:&error];

  NSArray *matches = [regex matchesInString:message 
                            options:0
                            range:NSMakeRange(0, [message length])];

  // if ([matches count] == 0)
    // return write(fd, buffer, len);

  for (NSTextCheckingResult *match in matches) {

    if ([match numberOfRanges] < 6) {
      //write(fd, buffer, len); // if entry doesn't match regex, print uncolored
      continue;
    }

    // NSRange dateRange    =  [match rangeAtIndex:1];
    // NSRange deviceRange  =  [match rangeAtIndex:2];
    NSRange processRange =  [match rangeAtIndex:3];
    // NSRange pidRange     =  [match rangeAtIndex:4];
    NSRange typeRange    =  [match rangeAtIndex:5];
    NSRange logRange     =  [match rangeAtIndex:6];

    // NSString *date       =  [message substringWithRange:dateRange];
    // NSString *device     =  [message substringWithRange:deviceRange];
    NSString *process    =  [message substringWithRange:processRange];
    // NSString *pid        =  [message substringWithRange:pidRange];
    NSString *type       =  [message substringWithRange:typeRange];
    NSString *log        =  [message substringWithRange:
                                  NSMakeRange(logRange.location,
                                              [message length] - logRange.location)];

    log = [log stringByTrimmingCharactersInSet:
                [NSCharacterSet newlineCharacterSet]];

    NSMutableString *build = [NSMutableString new];

    // [build appendString:@COLOR_DARK_WHITE];
    // [build appendString:date];
    // [build appendString:@" "];
    // [build appendString:device];
    // [build appendString:@" "];

    // [build appendString:@COLOR_CYAN];
    [build appendString:process];
    // [build appendString:@"["];
    // [build appendString:pid];
    // [build appendString:@"]"];

    // [build appendString:@(darkTypeColor)];
    [build appendString:@" <"];
    // [build appendString:@(typeColor)];
    [build appendString:type];
    // [build appendString:@(darkTypeColor)];
    [build appendString:@">"];
    // [build appendString:@COLOR_RESET];
    [build appendString:@": "];
    [build appendString:log];

    [msgs addObject:build];
    
    }
    // printf("%s\n", [build UTF8String]);

    // Only save the 10 latest messages
    if([msgs count]>10){
      [msgs removeObjectAtIndex:0];
    }

    // Scroll to bottom
    NSString *ss=@"";
    int i = 0;
    for(NSString *s in msgs){
      ss = [NSString stringWithFormat:@"%@%i: %@\n",ss,i,s];
      i++;
    }
    [l setText:ss];

    [l setScrollEnabled:NO];
    [l setScrollEnabled:YES];
    [l scrollRangeToVisible:NSMakeRange([l.text length], 0)];
}

//Prevents touches from being blocked by the window
- (BOOL)_ignoresHitTest {
  return YES;
}

-(void)initActivatorListener{ // if it is installed
    dlopen("/usr/lib/libactivator.dylib", RTLD_LAZY);
    Class laactivatorClass = objc_getClass("LAActivator");
    if( laactivatorClass == nil ){
        NSLog(@"Class 'LAActivator' not found. Activator is not installed.");
    }else{
        [[laactivatorClass sharedInstance] registerListener:self forName:@"com.jontelang.syslogwindow.alpha"];
    }
}


- (void)activator:(LAActivator *)activator 
     receiveEvent:(LAEvent *)event 
  forListenerName:(NSString *)listenerName{
    if( [listenerName isEqualToString:@"com.jontelang.syslogwindow.alpha"] ){
        self.alpha = self.alpha == 1.0f ? 0.25f : 1.0f;
    }else{
        NSLog(@"hello");
    }
}

// - (void)activator:(LAActivator *)activator receiveDeactivateEvent:(LAEvent *)event{
//     if( snapperWindow != nil ){
//         if( [snapperWindow isCropping] || [snapperWindow isPresentingSnapperHistory] ){
//             [snapperWindow hideCropOverlay];
//             [snapperWindow hideSnapperHistory];
//             event.handled = YES;
//         }
//     }
// }

@end