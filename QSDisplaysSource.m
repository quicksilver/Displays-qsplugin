
#import "QSDisplaysSource.h"

#define QSDisplayParametersType @"QSDisplayParametersType"

#define QSDisplayIDType @"QSDisplayIDType"


#define fileTypesArray [NSArray arrayWithObjects:@"JPEG",@"PICT",@"TIFF",@"GIF",@"JPEG",@"JPG",@"PCT",@"PICT",@"PNG",@"TIF",@"PDF",nil]

void QSDetectDisplays(){
CGSDisplayStatusQuery();
	
	//kern_return_t IOServiceRequestProbe(  io_service_t service,  unsigned int options ); 
	/*
	 
	 
	 I'm using IOKit Right now I don't have the source code in front of me, but
	 there's an API there to rescan the devices.
	 You need to open a IOKit port and then call this API (It's a matter of
														   getting the IOMasterPort, then IOServiceMatching with the graphics
														   services).
	 Then the useful API is IOServiceRequestProbe, with the services found above,
	 and it does what we want
	*/
}

NSArray *QSResolutionObjectsForDisplayID(int displayID){
	if (!displayID)displayID=kCGDirectMainDisplay;
	
	NSArray *modes=(NSArray *)CGDisplayAvailableModes(displayID);
	
	NSMutableArray *objects=[NSMutableArray arrayWithCapacity:1];
	
	NSMutableSet *resolutions=[NSMutableSet set];
	QSObject *newObject;
	NSDictionary *mode;
    NSEnumerator *modeEnumer=[modes objectEnumerator];
    while(mode=[modeEnumer nextObject]){
		[resolutions addObject:[NSString stringWithFormat:@"%ldx%ld",(long)[[mode objectForKey:(NSString *)kCGDisplayWidth] integerValue],(long)[[mode objectForKey:(NSString *)kCGDisplayHeight] integerValue]]];
    }

	
	
	NSString *resolution;
    NSEnumerator *resolutionEnumer=[resolutions objectEnumerator];
    while(resolution=[resolutionEnumer nextObject]){
		NSArray *dim=[resolution componentsSeparatedByString:@"x"]; 
		NSNumber *width=[dim objectAtIndex:0];
		NSNumber *height=[dim objectAtIndex:1];
		NSString *description=[NSString stringWithFormat:@"%ld %C %ld Resolution", (long)[width integerValue], (unsigned short)0x00d7, (long)[height integerValue]];
        newObject=[QSObject makeObjectWithIdentifier:description];
		[newObject setName:description];
        [newObject setObject:[NSDictionary dictionaryWithObjectsAndKeys:width,kCGDisplayWidth,height,kCGDisplayHeight,nil] forType:QSDisplayParametersType];
        [newObject setPrimaryType:QSDisplayParametersType];
		[objects addObject:newObject];
    }
	
	
    return objects;
}

NSArray *QSColorDepthObjectsForDisplayID(int displayID){
	if (!displayID)displayID=kCGDirectMainDisplay;
	
	NSArray *modes=(NSArray *)CGDisplayAvailableModes(displayID);
	
	NSMutableArray *objects=[NSMutableArray arrayWithCapacity:1];
	
	NSMutableSet *depths=[NSMutableSet set];
	QSObject *newObject;
	NSDictionary *mode;
    NSEnumerator *modeEnumer=[modes objectEnumerator];
    while(mode=[modeEnumer nextObject]){
		[depths addObject:[mode objectForKey:(NSString *)kCGDisplayBitsPerPixel]];
    }
	
	NSDictionary *colorDict=[NSDictionary dictionaryWithObjectsAndKeys:@"Millions of Colors",@"32",@"Thousands of Colors",@"16",@"256 Colors",@"8",nil];
	NSNumber *depth;
    NSEnumerator *depthEnumer=[depths objectEnumerator];
    while(depth=[depthEnumer nextObject]){
		
		NSString *description=[colorDict objectForKey:[depth stringValue]];
		newObject=[QSObject makeObjectWithIdentifier:description];
		[newObject setName:description];
        [newObject setObject:[NSDictionary dictionaryWithObjectsAndKeys:depth,kCGDisplayBitsPerPixel,nil] forType:QSDisplayParametersType];
		[newObject setPrimaryType:QSDisplayParametersType];
		[newObject setObject:[NSString stringWithFormat:@"%ld bits per pixel",(long)[depth integerValue]]
					 forMeta:kQSObjectDetails];
		[objects addObject:newObject];
    }
    return objects;
}

NSArray *QSRefreshRateObjectsForDisplayID(int displayID){
	if (!displayID)displayID=kCGDirectMainDisplay;
	
	NSArray *modes=(NSArray *)CGDisplayAvailableModes(displayID);
	
	NSMutableArray *objects=[NSMutableArray arrayWithCapacity:1];
	
	NSMutableSet *rates=[NSMutableSet set];
	QSObject *newObject;
	NSDictionary *mode;
    NSEnumerator *modeEnumer=[modes objectEnumerator];
    while(mode=[modeEnumer nextObject]){
		[rates addObject:[mode objectForKey:(NSString *)kCGDisplayRefreshRate]];
    }
	
	NSNumber *rate;
    NSEnumerator *rateEnumer=[rates objectEnumerator];
    while(rate=[rateEnumer nextObject]){
		
		NSString *description=[NSString stringWithFormat:@"%@hz",[rate stringValue]];
		if (![rate integerValue])description=@"None (LCD)";
		newObject=[QSObject makeObjectWithIdentifier:description];
		[newObject setName:description];
        [newObject setObject:[NSDictionary dictionaryWithObjectsAndKeys:rate,kCGDisplayBitsPerPixel,nil] forType:QSDisplayParametersType];
		[newObject setPrimaryType:QSDisplayParametersType];
		[newObject setObject:@"Refresh Rate"
					 forMeta:kQSObjectDetails];
		[objects addObject:newObject];
    }
    return objects;
}

@implementation QSDisplaysObjectSource

 - (NSImage *) iconForEntry:(NSDictionary *)dict{
	NSImage *entryIcon=[[NSBundle bundleForClass:[self class]] imageNamed:@"Display"];
	[entryIcon createIconRepresentations];
    return entryIcon;
}
- (void)setQuickIconForObject:(QSObject *)object{
	if ([object objectForType:QSDisplayIDType]){
		[object setIcon:[[NSBundle bundleForClass:[self class]] imageNamed:@"Display"]];
		return;
	}
	if ([[object objectForType:QSDisplayParametersType]objectForKey:(NSString *)kCGDisplayWidth]){
		[object setIcon:[[NSBundle bundleForClass:[self class]] imageNamed:@"DisplayResolution"]];
	}else{
		[object setIcon:[[NSBundle bundleForClass:[self class]] imageNamed:@"DisplayDepth"]];
	}
}



- (BOOL)indexIsValidFromDate:(NSDate *)indexDate forEntry:(NSDictionary *)theEntry{
	return NO;
}

- (id)init{
	if (self=[super init]){
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(invalidateSelf) name:NSApplicationDidChangeScreenParametersNotification object: nil];
		
	}
	return self;
}


- (NSString *)identifierForObject:(QSObject *)object{
	NSString *ident=[@"[Display Parameters]:" stringByAppendingString:[object name]];
	return ident;
}


- (NSArray *)objectsForEntry:(NSDictionary *)theEntry{
	
	//NSLog(@"Scan Displays");
	NSMutableArray *objects=[NSMutableArray arrayWithCapacity:1];
	
	QSObject *newObject;
	
	
	id screen;
    NSArray *screens=[NSScreen screens];
	int i;
	for(i=0;i<[screens count];i++){
		screen=[screens objectAtIndex:i];
		
		newObject=[QSObject makeObjectWithIdentifier:[NSString stringWithFormat:@"[Screen]:%d",[screen screenNumber]]];
		
		
		[newObject setName:[NSString stringWithFormat:@"Display %d"]];
		[newObject setLabel:[screen deviceName]];
		[newObject setObject:[NSNumber numberWithInteger:[screen screenNumber]] forType:QSDisplayIDType];
		[newObject setPrimaryType:QSDisplayIDType];
	//	[newObject setObject:[NSString stringWithFormat:@"%d bits per pixel",[depth intValue]]
	//				 forMeta:kQSObjectDetails];
		[objects addObject:newObject];
		
	}
	
	
	return objects;
	
}


@end



#define kQSDisplayParametersApplyAction @"QSDisplayParametersApplyAction"


@implementation QSDisplaysActionProvider

// for the set desktop picture action
- (NSArray *) validActionsForDirectObject:(QSObject *)dObject indirectObject:(QSObject *)iObject {
    // doesn't work with the comma trick
    if ([dObject count] == 1) {
        NSString *extension = nil;
        if ([dObject objectForType:QSFilePathType]) {
            // Files
            extension = [[dObject objectForType:QSFilePathType] pathExtension];
        } else if ([dObject objectForType:QSURLType]) {
            // URLS
            extension = [[dObject objectForType:QSURLType] pathExtension];
        } else {
            return nil;
        }
        // the action's only valid for images
        BOOL inArray = [fileTypesArray containsObject:[extension uppercaseString]]; 
        if (inArray) {
            return [NSArray arrayWithObject:@"DesktopPictureAction"];
        }
    }
return nil;
}

- (NSArray *)validIndirectObjectsForAction:(NSString *)action directObject:(QSObject *)dObject{
	
    if ([action isEqualToString:@"DesktopPictureAction"]) {
        NSArray *objects= (NSArray *)[QSLib scoredArrayForString:nil inSet:[QSLib arrayForType:@"QSDisplayIDType"]];
        return objects;
    }
    
	NSInteger displayID= [[dObject objectForType:QSDisplayIDType] integerValue];
	
	//NSLog(@"action %@",action);
	if ([action isEqualToString:@"QSDisplaySetDepthAction"])
		return QSColorDepthObjectsForDisplayID(displayID);
	if ([action isEqualToString:@"QSDisplaySetResolutionAction"])
		return QSResolutionObjectsForDisplayID(displayID);
	if ([action isEqualToString:@"QSDisplaySetRefreshRateAction"])
		return QSRefreshRateObjectsForDisplayID(displayID);
	
	return nil;// QSPropertiesObjectsForDisplayID(displayID);
}

#pragma mark Set Desktop Picture action
- (QSObject *) setDesktop:(QSObject *)dObject onScreen:(QSObject *)iObject {
    
    // deal with URLs - download the remote file
    NSURL *fileURL = nil;
    if ([dObject objectForType:QSURLType])
    {
        fileURL = [self getRemoteFile:[NSURL URLWithString:[dObject objectForType:QSURLType]]];
    } else  {
        fileURL = [NSURL fileURLWithPath:[dObject singleFilePath]];
    }
    if (!fileURL) {
        // warn the user something went wrong
        NSImage *image = [QSResourceManager imageNamed:@"SetDesktop" inBundle:[NSBundle bundleForClass:[self class]]];
        NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:@"DisplaysPlugin", QSNotifierType, image, QSNotifierIcon, @"Failed to set Desktop Picture", QSNotifierTitle, @"Image file not found", QSNotifierText, nil];
        QSShowNotifierWithAttributes(dict);
        return nil;
    }
    
    NSScreen *screen = nil;
    
    // get the screen either default screen (with keyboard focus or the iObject screen
	if(iObject) {
        screen = [NSScreen screenWithNumber:[[iObject objectForType:@"QSDisplayIDType"] integerValue]];
	} else {
        screen = [NSScreen mainScreen];
	}
    NSError *err = nil;
    [[NSWorkspace sharedWorkspace] setDesktopImageURL:fileURL forScreen:screen options:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO],NSWorkspaceDesktopImageAllowClippingKey,nil] error:&err];
    
    if (err) {
        NSLog(@"Error: %@",err);
    }
    return nil;
}

- (NSURL *) getRemoteFile:(NSURL *)fileURL {
    NSError *err = nil;
    NSData *image = [NSData dataWithContentsOfURL:fileURL options:0 error:&err];
    if (err) {
        NSLog(@"Error: %@:",err);
    }
    if (!image) {
        return nil;
    }
    NSString *tempFile = [NSTemporaryDirectory() stringByAppendingFormat:@"%@.%@",[NSString uniqueString],[fileURL pathExtension]];
    [image writeToFile:tempFile atomically:YES];
    return [NSURL fileURLWithPath:tempFile];
}

# pragma mark other Screen actions


- (QSObject *) selectNetwork:(QSObject *)dObject{
	// NSLog(@"Dict %@",[dObject objectForType:QSDisplayParametersType]);
	[self applyParameters:[dObject objectForType:QSDisplayParametersType] toDisplayID:0];
    return nil;
}
- (QSObject *) applyParameters:(QSObject *)dObject toDisplay:(QSObject *)iObject{
	// NSLog(@"Dict %@",);
	[self applyParameters:[dObject objectForType:QSDisplayParametersType]
			  toDisplayID:[[iObject objectForType:QSDisplayIDType] integerValue]];
    return nil;
}




- (void)applyParameters:(NSDictionary *)parameters toDisplayID:(CGDirectDisplayID)displayID{
	
    boolean_t exactMatch;
    CFDictionaryRef mode;
    CGDisplayErr err;
	
	if (!displayID)displayID=kCGDirectMainDisplay;
    
    NSMutableDictionary *originalMode = [[(id)CGDisplayCurrentMode( displayID ) mutableCopy] autorelease];
	
	if ( originalMode == NULL )
        return;

	[originalMode addEntriesFromDictionary:parameters];
	   
    mode = CGDisplayBestModeForParameters(displayID,
                                          [[originalMode objectForKey:(NSString *)kCGDisplayBitsPerPixel] integerValue],
                                          [[originalMode objectForKey:(NSString *)kCGDisplayWidth] integerValue],
                                          [[originalMode objectForKey:(NSString *)kCGDisplayHeight] integerValue],
                                          &exactMatch);
    
    err = CGDisplaySwitchToMode(displayID, mode);
		
	CGDisplayConfigRef configRef;
	
	///еее OS 10.3 and above only!
	   // setup display switch configuration
	   CGBeginDisplayConfiguration(&configRef);
	   CGConfigureDisplayMode(configRef, kCGDirectMainDisplay, mode);
	   CGConfigureDisplayFadeEffect(configRef, 2.0f, 2.0f,     // 3 second fade out and in
									1.0f, 0.0f, 0.0f);         // fade to black
	   err = CGCompleteDisplayConfiguration(configRef, kCGConfigurePermanently);
	   if ( err != CGDisplayNoErr )
		   NSLog(@"error %d",err);
	   // Switch to new mode
	   //err = CGDisplaySwitchToMode(kCGDirectMainDisplay, mode);
	   
	   
}

@end

//CGConfigureDisplayFadeEffect

//Use fade to white
