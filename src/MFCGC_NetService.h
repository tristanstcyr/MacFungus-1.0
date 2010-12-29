#import <MFClientGameController.h>

@interface MFClientGameController(NSNetServiceDelegation)
- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser 
	    didFindService:(NSNetService *)aNetService 
	    moreComing:(BOOL)moreComing;
- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser 
	    didRemoveService:(NSNetService *)aNetService 
	    moreComing:(BOOL)moreComing;
- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)aNetServiceBrowser;
- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser 
	    didNotSearch:(NSDictionary *)errorDict;
- (void)netServiceBrowserWillSearch:(NSNetServiceBrowser *)aNetServiceBrowser;
- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser 
	    didFindDomain:(NSString *)domainString 
	    moreComing:(BOOL)moreComing;
- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser 
	    didRemoveDomain:(NSString *)domainString 
	    moreComing:(BOOL)moreComing;
@end
