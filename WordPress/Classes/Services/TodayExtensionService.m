#import "TodayExtensionService.h"
#import <NotificationCenter/NotificationCenter.h>
#import "Constants.h"
#import "SFHFKeychainUtils.h"

@implementation TodayExtensionService

- (void)configureTodayWidgetWithSiteID:(NSNumber *)siteID blogName:(NSString *)blogName siteTimeZone:(NSTimeZone *)timeZone andOAuth2Token:(NSString *)oauth2Token
{
    NSAssert(siteID != nil, @"Site ID should not be nil");
    NSAssert(blogName != nil, @"Blog name should not be nil");
    NSAssert(timeZone != nil, @"Timezone should not be nil");
    NSAssert(oauth2Token.length > 0, @"OAuth2 token should be provided");
    
    if (!WIDGETS_EXIST) {
        return;
    }
    
    // Save the token and site ID to shared user defaults for use in the today widget
    NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:WPAppGroupName];
    [sharedDefaults setObject:timeZone.name forKey:WPStatsTodayWidgetUserDefaultsSiteTimeZoneKey];
    [sharedDefaults setObject:siteID forKey:WPStatsTodayWidgetUserDefaultsSiteIdKey];
    [sharedDefaults setObject:blogName forKey:WPStatsTodayWidgetUserDefaultsSiteNameKey];
    [sharedDefaults synchronize];
    
    NSError *error;
    [SFHFKeychainUtils storeUsername:WPStatsTodayWidgetOAuth2TokenKeychainUsername
                         andPassword:oauth2Token
                      forServiceName:WPStatsTodayWidgetOAuth2TokenKeychainServiceName
                         accessGroup:WPStatsTodayWidgetOAuth2TokenKeychainAccessGroup
                      updateExisting:YES
                               error:&error];
    if (error) {
        DDLogError(@"Today Widget OAuth2Token error: %@", error);
    } else {
        // Turns the widget on for this site
        [[NCWidgetController widgetController] setHasContent:YES forWidgetWithBundleIdentifier:@"org.wordpress.WordPressTodayWidget"];
    }
}

- (void)removeTodayWidgetConfiguration
{
    if (NSClassFromString(@"NCWidgetController") == nil) {
        return;
    }
    
    NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:WPAppGroupName];
    [sharedDefaults removeObjectForKey:WPStatsTodayWidgetUserDefaultsSiteTimeZoneKey];
    [sharedDefaults removeObjectForKey:WPStatsTodayWidgetUserDefaultsSiteIdKey];
    [sharedDefaults removeObjectForKey:WPStatsTodayWidgetUserDefaultsSiteNameKey];
    [sharedDefaults synchronize];
    
    [SFHFKeychainUtils deleteItemForUsername:WPStatsTodayWidgetOAuth2TokenKeychainUsername
                              andServiceName:WPStatsTodayWidgetOAuth2TokenKeychainServiceName
                                 accessGroup:WPStatsTodayWidgetOAuth2TokenKeychainAccessGroup
                                       error:nil];
    
    // Turns the widget off for this site
    [[NCWidgetController widgetController] setHasContent:NO forWidgetWithBundleIdentifier:@"org.wordpress.WordPressTodayWidget"];
}

- (void)hideTodayWidgetIfNotConfigured
{
    if (NSClassFromString(@"NCWidgetController") == nil) {
        return;
    }
    
    NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:WPAppGroupName];
    NSString *siteId = [sharedDefaults stringForKey:WPStatsTodayWidgetUserDefaultsSiteIdKey];
    NSString *oauth2Token = [SFHFKeychainUtils getPasswordForUsername:WPStatsTodayWidgetOAuth2TokenKeychainUsername
                                                       andServiceName:WPStatsTodayWidgetOAuth2TokenKeychainServiceName
                                                          accessGroup:WPStatsTodayWidgetOAuth2TokenKeychainAccessGroup
                                                                error:nil];
    
    if (siteId.length == 0 || oauth2Token.length == 0) {
        [[NCWidgetController widgetController] setHasContent:NO forWidgetWithBundleIdentifier:@"org.wordpress.WordPressTodayWidget"];
    } else {
        [[NCWidgetController widgetController] setHasContent:YES forWidgetWithBundleIdentifier:@"org.wordpress.WordPressTodayWidget"];
    }
}

@end
