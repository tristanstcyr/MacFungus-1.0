//
//  MFCGC_NetService.m
//  MacFungus
//
//  Created by tristan on 20/08/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "MFCGC_NetService.h"


@implementation MFClientGameController(NSNetServiceDelegation)
- (void)setupBrowser
{
	[domainBrowser searchForAllDomains];
	[serviceBrowser searchForServicesOfType:MF_PROTOCOL inDomain:@""];
	[discoveredServices removeAllObjects];
}
- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser 
	    didFindService:(NSNetService *)aNetService 
	    moreComing:(BOOL)moreComing
{
    NSLog( @"Found service named %@.", [aNetService name] );
	
    [discoveredServices addObject:aNetService];
    [aNetService setDelegate:self];
    [aNetService resolve];
    
    if ( !moreComing )
	[browserTableView reloadData];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser 
	    didRemoveService:(NSNetService *)aNetService 
	    moreComing:(BOOL)moreComing
{
    [discoveredServices removeObject:aNetService];
    
    if ( !moreComing )
		[browserTableView reloadData];
}

- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)aNetServiceBrowser
{
    if ( aNetServiceBrowser == serviceBrowser ) {
		[discoveredServices removeAllObjects];
		[browserTableView reloadData];
    }    
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser 
	    didNotSearch:(NSDictionary *)errorDict
{
    NSLog(@"There was an error in searching. Error Dictionary follows...");
    NSLog( [errorDict description] );
}

- (void)netServiceBrowserWillSearch:(NSNetServiceBrowser *)aNetServiceBrowser
{
    if ( aNetServiceBrowser == domainBrowser ) 
	NSLog(@"Looking for local domains...");
    else
	NSLog(@"Looking for local services...");
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser 
	    didFindDomain:(NSString *)domainString 
	    moreComing:(BOOL)moreComing
{
	NSLog( @"Found domain %@.", domainString );
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser 
	    didRemoveDomain:(NSString *)domainString 
	    moreComing:(BOOL)moreComing
{
	NSLog( @"Removed domain %@.", domainString );
}
@end
