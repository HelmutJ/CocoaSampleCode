/* This program is freely distributable without licensing fees
   and is provided without guarantee or warrantee expressed or
   implied. This program is -not- in the public domain. */

#import <Cocoa/Cocoa.h>

#define GLUT_DEFER_PREFS_DEVICE_QUERY  1

@interface GLUTPreferencesController : NSWindowController
{
#if GLUT_DEFER_PREFS_DEVICE_QUERY
   IBOutlet NSTabView *prefsTabView;
#endif

   /* Launch */
   IBOutlet NSButton *launchUseMacOSXCoords;
   IBOutlet NSButton *launchUseCurrWD;
   IBOutlet NSButton *launchUseExtendedDesktop;
   IBOutlet NSButton *launchIconic;
   IBOutlet NSButton *launchDebugMode;
   IBOutlet NSButton *launchGamemodeCaptureSingle;
   IBOutlet NSButton *launchSyncToVBL;
   IBOutlet NSTextField *launchInitWidth;
   IBOutlet NSTextField *launchInitHeight;
   IBOutlet NSTextField *launchInitX;
   IBOutlet NSTextField *launchInitY;
   IBOutlet NSTextField *launchMenuIdle;
   IBOutlet NSTextField *launchFadeTime;

   /* Mouse */
   IBOutlet NSTextField *mouseDetected;
   IBOutlet NSButton *mouseEmulation;
   IBOutlet NSPopUpButton *mouseMiddleConfigMenu;
   IBOutlet NSPopUpButton *mouseRightConfigMenu;
   IBOutlet NSTextField *mouseAssignWarningText;
   IBOutlet NSImageView *mouseAssignWarningIcon;
   NSView *mouseTabItemView;
   
   /* Joystick */
   IBOutlet NSPopUpButton *joyDeviceMenu;
   IBOutlet NSPopUpButton *joyInputMenu;
   IBOutlet NSButton *joyInverted;
   IBOutlet NSButton *joyAssign;
   IBOutlet NSTextField *joyElement;
   IBOutlet NSTextField *joyAssignNote;
   IBOutlet NSImageView *joyAssignWarningIcon;
   NSView *joyTabItemView;

   /* Spaceball */
   IBOutlet NSPopUpButton *spaceDeviceMenu;
   IBOutlet NSPopUpButton *spaceInputMenu;
   IBOutlet NSButton *spaceInverted;
   IBOutlet NSButton *spaceAssign;
   IBOutlet NSTextField *spaceElement;
   IBOutlet NSTextField *spaceAssignNote;
   IBOutlet NSImageView *spaceAssignWarningIcon;
   NSView *spaceTabItemView;

   BOOL updatingDevices;
}

- (IBAction)ok:(id)sender;
- (IBAction)cancel:(id)sender;
- (IBAction)spaceAssign:(id)sender;
- (IBAction)setDefault:(id)sender;

- (IBAction)launchUseMacOSCoords:(id)sender;
- (IBAction)launchUseCurrWD:(id)sender;
- (IBAction)launchUseExtDesktop:(id)sender;
- (IBAction)launchIconic:(id)sender;
- (IBAction)launchDebugMode:(id)sender;
- (IBAction)launchGamemodeCaptureSingle:(id)sender;
- (IBAction)mouseEanbleEmulation:(id)sender;
- (IBAction)mouseMiddleMenu:(id)sender;
- (IBAction)mouseRightMenu:(id)sender;
- (IBAction)joyDevice:(id)sender;
- (IBAction)joyElement:(id)sender;
- (IBAction)joyInvert:(id)sender;
- (IBAction)joyAssign:(id)sender;
- (IBAction)spaceDevice:(id)sender;
- (IBAction)spaceElement:(id)sender;
- (IBAction)spaceInvert:(id)sender;
- (IBAction)spaceAssign:(id)sender;

@end

extern NSString *GLUTMousePresetKey;
extern NSString *GLUTMouseCustomMiddleModifiersKey;
extern NSString *GLUTMouseCustomRightModifiersKey;
extern NSString *GLUTPreferencesName;
