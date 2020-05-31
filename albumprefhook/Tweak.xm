#import <UIKit/UIKit.h>
#import <Photos/Photos.h>
#import <notify.h>

#define PLIST_PATH_Settings "/var/mobile/Library/Preferences/com.julioverne.albumpref.plist"



static BOOL Enabled;
static BOOL Heart;
static NSString* albumName;
static NSString* albumId;


@interface PHCollection ()
@property (nonatomic,readonly) unsigned long long estimatedPhotosCount;
@property (nonatomic,readonly) unsigned long long estimatedVideosCount;
@end

@interface PXMessagesRecentPhotosGadget : NSObject
@property (nonatomic, retain) UIViewController *recentPhotosViewController;

- (UIViewController*)contentViewController;
@end

static void saveCurrent()
{
	@autoreleasepool {
		NSMutableDictionary *Prefs = [[[NSDictionary alloc] initWithContentsOfFile:@PLIST_PATH_Settings]?:@{} mutableCopy];
		Prefs[@"Enabled"] = Enabled?@YES:@NO;
		if(albumName) {
			Prefs[@"albumName"] = albumName;
		}
		if(albumId) {
			Prefs[@"albumId"] = albumId;
		}
		[Prefs writeToFile:@PLIST_PATH_Settings atomically:YES];
		notify_post("com.julioverne.albumpref/SettingsChanged");
		exit(0);
	}
}

%hook PXMessagesRecentPhotosGadget
- (id)localizedTitle
{	
	if(Enabled&&albumName!=nil) {
		return albumName;
	}
	return %orig;
}

- (void)_updateViewControllerInsets
{
	%orig;
	if(Enabled&&Heart) {
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1f * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
			UIView* topView = [[[[self contentViewController].view superview] superview] superview];
			UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];
			[button setTitleColor:[UIColor colorWithRed:0.24 green:0.24 blue:1.00 alpha:1.0] forState:UIControlStateNormal];
			[button addTarget:self action:@selector(preferedAlbumPrompt) forControlEvents:UIControlEventTouchUpInside];
			[button setTitle:@"♡" forState:UIControlStateNormal];
			button.frame = CGRectMake(0, 0, 30, 30);
			button.center = topView.center;
			button.frame = CGRectMake(button.frame.origin.x+(button.frame.origin.x/3), 10, button.frame.size.width, button.frame.size.height);
			button.tag = 11;
			UIView* oldV = [topView viewWithTag:11];
			if(oldV) {
				[oldV removeFromSuperview];
			}
			[topView addSubview:button];
		});
	}
}
%new
- (void)preferedAlbumPrompt
{
	NSMutableDictionary* albumList = [[NSMutableDictionary alloc] init];
	
	NSArray *collectionsFetchResults;
	PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
	PHFetchResult *syncedAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumSyncedAlbum options:nil];
	PHFetchResult *momAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeMoment subtype:PHAssetCollectionSubtypeSmartAlbumGeneric options:nil];
	PHFetchResult *userCollections = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];
	
	collectionsFetchResults = @[smartAlbums, momAlbums, userCollections, syncedAlbums];
	
	for (int i = 0; i < collectionsFetchResults.count; i ++) {
		PHFetchResult *fetchResult = collectionsFetchResults[i];
		for (int x = 0; x < fetchResult.count; x ++) {
			PHCollection *collection = fetchResult[x];
			//if((collection.estimatedPhotosCount>0||collection.estimatedVideosCount>0)||collection.canContainAssets||collection.canContainAssets) {
				if(collection.localIdentifier&&collection.localizedTitle) {
					albumList[[NSString stringWithFormat:@"%@", collection.localIdentifier]] = [NSString stringWithFormat:@"%@", collection.localizedTitle];
				}
			//}
		}
	}
	
	albumList[@"default"] = @"Default";
	
	NSDictionary *Prefs = [[[NSDictionary alloc] initWithContentsOfFile:@PLIST_PATH_Settings]?:@{} copy];
	
	NSDictionary *PrefsAlbum = Prefs[@"album"]?:@{};
	
	for(NSString* a in [PrefsAlbum allKeys]) {
		albumList[a] = PrefsAlbum[a];
	}
	
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"AlbumPref" message:@"Choose Preferred Album" preferredStyle:UIAlertControllerStyleAlert];
	
	UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
	[alert addAction:cancel];
	
	for(NSString* keyNow in [albumList allKeys]) {
		UIAlertAction *action = [UIAlertAction actionWithTitle:albumList[keyNow] style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
			PHFetchResult* result = [%c(PHAssetCollection) fetchAssetCollectionsWithLocalIdentifiers:@[albumId] options:nil];
			if(!result || result.count<1) {
				return;
			}
			albumName = albumList[keyNow];
			albumId = keyNow;	
			saveCurrent();
		}];
		[alert addAction:action];
	}
    [self.recentPhotosViewController presentViewController:alert animated:YES completion:nil];
}
%end

%hook PHAssetCollection
+(id)fetchAssetCollectionsWithType:(long long)arg1 subtype:(long long)arg2 options:(id)arg3
{
	if(Enabled&&albumId!=nil) {
		return [%c(PHAssetCollection) fetchAssetCollectionsWithLocalIdentifiers:@[albumId] options:nil];
	}
	return %orig(arg1, arg2, arg3);
}
%end



static void settingsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	@autoreleasepool {
		NSDictionary *Prefs = [[[NSDictionary alloc] initWithContentsOfFile:@PLIST_PATH_Settings]?:@{} copy];
		Enabled = (BOOL)[Prefs[@"Enabled"]?:@YES boolValue];
		Heart = (BOOL)[Prefs[@"Heart"]?:@YES boolValue];
		albumName = Prefs[@"albumName"]!=nil?[Prefs[@"albumName"] copy]:nil;
		albumId = Prefs[@"albumId"]!=nil?[Prefs[@"albumId"] copy]:nil;
		if(albumId&&[albumId isEqualToString:@"default"]) {
			albumName = nil;
			albumId = nil;
		}
	}
}

%ctor
{
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, settingsChanged, CFSTR("com.julioverne.albumpref/SettingsChanged"), NULL, CFNotificationSuspensionBehaviorCoalesce);
	settingsChanged(NULL, NULL, NULL, NULL, NULL);
	dlopen("/System/Library/PrivateFrameworks/PhotosUICore.framework/PhotosUICore", RTLD_LAZY);
	%init;
}