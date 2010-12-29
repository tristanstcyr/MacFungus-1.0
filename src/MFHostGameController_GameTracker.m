#import "MFHostGameController.h"
#import "GSNSDataExtensions.h"
#import <openssl/md5.h>
#import <openssl/blowfish.h>
#define REFRESH_INTERVAL 55.0f

@implementation MFHostGameController (GameTracker)

- (void)startTrackerTimer
{
	NSLog(@"timer started");
	NSRunLoop *loop = [NSRunLoop currentRunLoop];
	trackerTimer = [NSTimer timerWithTimeInterval:REFRESH_INTERVAL
									target:self
								  selector:@selector(updateTracker)
								  userInfo:nil
								   repeats:YES];
	[loop addTimer:trackerTimer forMode:NSDefaultRunLoopMode];
	[self updateTracker];
}

- (void)stopTrackerTimer
{
	if (trackerTimer)
	{	
		[self updateTracker];
		[trackerTimer invalidate];
		trackerTimer = nil;
	}
}

- (void)updateTracker
{
	int numPlayers = (players != nil ? [players count] : 0);
	int maxPlayers = 4;
	NSString *gameName, *gameDescription;
	
	if (numPlayers == 0)
		NSLog(@"players were 0");
	
	{ // The description and name from the prefs
		NSTextField *gameNameField = [appController valueForKey:@"gameNameField"];
		NSTextField *gameDescriptionField = [appController valueForKey:@"gameDescriptionField"];
		
		if ([[gameNameField stringValue] length] <= 0)
			gameName = [[gameNameField cell] placeholderString];
		else
			gameName = [gameNameField stringValue];
		
		if ([[gameDescriptionField stringValue] length] <= 0)
			gameDescription = [[gameDescriptionField cell] placeholderString];
		else
			gameDescription = [gameDescriptionField stringValue];
	}
	
	NSString* versionString = [[[NSBundle mainBundle]infoDictionary]objectForKey:@"CFBundleVersion"];
	unsigned int key = (numPlayers+PORT_NUMBER)*23;
	
	// md5 hash of the key
	int keyLength, j;
	char keyString[8];
	keyLength = sprintf(keyString, "%d", key);
	unsigned char digest[16];
	char md5key[32];
	MD5((const unsigned char*)keyString,keyLength,digest);
	for(j=0;j<16;j++) sprintf(md5key+j*2,"%02x",digest[j]);
	
	NSString* msgString = [NSString stringWithFormat:@"%@;%@;%@;%i;%i;%i;%s;",
																			gameName, gameDescription, versionString, numPlayers, maxPlayers, PORT_NUMBER, md5key];
	NSLog(msgString);
	NSString* urlString = [NSString stringWithFormat:@"http://macfungus.moritzjoesch.de/submit.php?string=%@",
												[[msgString encryptStringWithPassword:@"ATduRYsi"] replaceMatchingCharacters:'+' withString:@"%2B"]];
	// Contact the URL
	NSLog(@"%@", urlString);
	NSURL *url = [NSURL URLWithString:urlString];
	NSURLRequest *request = [NSURLRequest requestWithURL:url];
	[[NSURLConnection connectionWithRequest:request delegate:nil] retain];
}
@end

@implementation NSString (ReplaceAndEncode)

- (NSString*)replaceMatchingCharacters:(char)character withString:(NSString*)replacement
{
	NSMutableString* temp = [[NSMutableString alloc] initWithString:self];
	int j;
	for(j=0;j<[temp length];j++) {
		if([temp characterAtIndex:j] == character) {
			[temp replaceCharactersInRange:NSMakeRange(j,1) withString:replacement];
		}
	}
	
	return [temp autorelease];
}

- (NSString*)encryptStringWithPassword:(NSString*)password
{
	BF_KEY key;
	BF_set_key(&key, [password cStringLength], (const unsigned char*)[password cString]);
	long length = [self length];
	long adjustedLength = (length > 0) ? (length+(8-(length%8))) : length;  // length must be a multiply of 8 when using CBC mode
	unsigned char c[adjustedLength];  // input
	unsigned char b[adjustedLength];  // output
	int i=0;
	for( ; i < length; i++) {
		c[i] = [self characterAtIndex:i];
	}
	for( ; i < adjustedLength; i++) {
		c[i] = '\0';
	}
	unsigned char ivec[] = {'0','0','0','0','0','0','0','0'};
	BF_cbc_encrypt(c, b, adjustedLength, &key, ivec, BF_ENCRYPT);
	
	return [[[[NSData alloc] initWithBytes:b length:adjustedLength] base64EncodingWithLineLength:0] autorelease];
}
@end