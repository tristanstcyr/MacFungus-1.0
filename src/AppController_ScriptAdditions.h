#import <Cocoa/Cocoa.h>
#import <AppController.h>
@interface AppController (ScriptingSupport)
- (NSString *)scriptCommandHostGameWithName:(NSString *)name;
- (NSString *)scriptCommandJoinGame:(NSString *)addressString withName:(NSString *)name;
@end
