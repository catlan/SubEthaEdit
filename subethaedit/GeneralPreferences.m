//
//  GeneralPreferences.m
//  SubEthaEdit
//
//  Created by Martin Ott on Mon Mar 29 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "GeneralPreferences.h"
#import "TCMMMUserManager.h"
#import "TCMMMUser.h"
#import "TCMMMUserSEEAdditions.h"
#import "DocumentModeManager.h"
#import <AddressBook/AddressBook.h>


NSString * const MyColorHuePreferenceKey             = @"MyColorHue";
NSString * const CustomMyColorHuePreferenceKey       = @"CustomMyColorHue";
NSString * const SelectionSaturationPreferenceKey    = @"MySelectionSaturation";
NSString * const ChangesSaturationPreferenceKey      = @"MyChangesSaturation";
NSString * const HighlightChangesPreferenceKey       = @"HighlightChanges";
NSString * const HighlightChangesAlonePreferenceKey  = @"HighlightChangesAlone";
NSString * const OpenDocumentOnStartPreferenceKey    = @"OpenDocumentOnStart";
NSString * const ModeForNewDocumentsPreferenceKey    = @"ModeForNewDocuments";
NSString * const AdditionalShownPathComponentsPreferenceKey = @"AdditionalShownPathComponents";
NSString * const SelectedMyColorPreferenceKey        = @"SelectedMyColor";
NSString * const MyNamePreferenceKey    = @"MyName";
NSString * const MyAIMPreferenceKey     = @"MyAIM";
NSString * const MyEmailPreferenceKey   = @"MyEmail";
NSString * const MyAIMIdentifierPreferenceKey  =@"MyAIMIdentifier";
NSString * const MyEmailIdentifierPreferenceKey=@"MyEmailIdentifier";
NSString * const MyNamesPreferenceKey = @"MyNames";
NSString * const MyAIMsPreferenceKey  = @"MyAIMs";
NSString * const MyEmailsPreferenceKey= @"MyEmails";

@implementation GeneralPreferences

+ (void)initialize {
    NSMutableDictionary *defaultDict = [NSMutableDictionary dictionary];
    
    [defaultDict setObject:[NSNumber numberWithFloat:25.0]
                    forKey:ChangesSaturationPreferenceKey];
    [defaultDict setObject:[NSNumber numberWithFloat:45.0]
                    forKey:SelectionSaturationPreferenceKey];
    [defaultDict setObject:[NSNumber numberWithFloat:0.0]
                    forKey:CustomMyColorHuePreferenceKey];
    [defaultDict setObject:[NSNumber numberWithFloat:50.0]
                    forKey:MyColorHuePreferenceKey];
    [defaultDict setObject:[NSArray array]
                    forKey:MyNamesPreferenceKey];
    [defaultDict setObject:[NSArray array]
                    forKey:MyAIMsPreferenceKey];
    [defaultDict setObject:[NSArray array]
                    forKey:MyEmailsPreferenceKey];
    [defaultDict setObject:[NSNumber numberWithBool:YES]
                    forKey:OpenDocumentOnStartPreferenceKey];
    [defaultDict setObject:[NSNumber numberWithInt:0]
                    forKey:AdditionalShownPathComponentsPreferenceKey];
    [defaultDict setObject:[NSNumber numberWithBool:YES]
                    forKey:HighlightChangesPreferenceKey];
    [defaultDict setObject:[NSNumber numberWithBool:NO]
                    forKey:HighlightChangesAlonePreferenceKey];
                    
    [defaultDict setObject:BASEMODEIDENTIFIER
                    forKey:ModeForNewDocumentsPreferenceKey];
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultDict];
    
}

#define COLORMENUIMAGEWIDTH 20.
#define COLORMENUIMAGEHEIGHT 10.

- (NSImage *)TCM_menuImageWithColor:(NSColor *)aColor {
    NSRect rect=NSMakeRect(0,0,COLORMENUIMAGEWIDTH,COLORMENUIMAGEHEIGHT);
    NSImage *image=[[NSImage alloc] initWithSize:rect.size];
    [image lockFocus];
    [aColor drawSwatchInRect:rect];
//    [aColor set];
//    NSRectFill(rect);
    [[NSColor blackColor] set];
    [NSBezierPath strokeRect:rect];
    [image unlockFocus];
    
    return [image autorelease];
}

- (void)TCM_setupComboBoxes {
    ABPerson *meCard=[[ABAddressBook sharedAddressBook] me];
    ABMultiValue *emails=[meCard valueForProperty:kABEmailProperty];
    int index=0;
    int count=[emails count];
    for (index=0;index<count;index++) {
        [O_emailComboBox addItemWithObjectValue:[emails valueAtIndex:index]];
    }
    ABMultiValue *aims=[meCard valueForProperty:kABAIMInstantProperty];
    index=0;
    count=[aims count];
    for (index=0;index<count;index++) {
        [O_aimComboBox addItemWithObjectValue:[aims valueAtIndex:index]];
    }
}

- (IBAction)changeName:(id)aSender {
    TCMMMUser *me=[TCMMMUserManager me];
    NSString *newValue=[O_nameTextField stringValue];
    if (![[me name] isEqualTo:newValue]) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:newValue forKey:MyNamePreferenceKey];
        [me setName:newValue];
        [TCMMMUserManager didChangeMe];
    }
}

- (IBAction)changeAIM:(id)aSender {
    TCMMMUser *me=[TCMMMUserManager me];
    NSString *newValue=[O_aimComboBox stringValue];
    if (![[[me properties] objectForKey:@"AIM"] isEqualTo:newValue]) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:newValue forKey:MyAIMPreferenceKey];
        ABPerson *meCard=[[ABAddressBook sharedAddressBook] me];
        ABMultiValue *aims=[meCard valueForProperty:kABAIMInstantProperty];
        int index=0;
        int count=[aims count];
        for (index=0;index<count;index++) {
            if ([newValue isEqualToString:[aims valueAtIndex:index]]) {
                NSString *identifier=[aims identifierAtIndex:index];
                [defaults setObject:identifier forKey:MyAIMIdentifierPreferenceKey];
                break;
            }
        }
        if (count==index) {
            [defaults removeObjectForKey:MyAIMIdentifierPreferenceKey];
        }
        [[me properties] setObject:newValue forKey:@"AIM"];
        [TCMMMUserManager didChangeMe];
    }
}

- (IBAction)changeModeForNewDocuments:(id)aSender {
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    [defaults setObject:[aSender selectedModeIdentifier] forKey:ModeForNewDocumentsPreferenceKey];
}


- (IBAction)changeEmail:(id)aSender {
    TCMMMUser *me=[TCMMMUserManager me];
    NSString *newValue=[O_emailComboBox stringValue];
    if (![[[me properties] objectForKey:@"Email"] isEqualTo:newValue]) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:newValue forKey:MyEmailPreferenceKey];
        ABPerson *meCard=[[ABAddressBook sharedAddressBook] me];
        ABMultiValue *emails=[meCard valueForProperty:kABEmailProperty];
        int index=0;
        int count=[emails count];
        for (index=0;index<count;index++) {
            if ([newValue isEqualToString:[emails valueAtIndex:index]]) {
                NSString *identifier=[emails identifierAtIndex:index];
                [defaults setObject:identifier forKey:MyEmailIdentifierPreferenceKey];
                break;
            }
        }
        if (count==index) {
            [defaults removeObjectForKey:MyEmailIdentifierPreferenceKey];
        }
        [[me properties] setObject:newValue forKey:@"Email"];
        [TCMMMUserManager didChangeMe];
    }
}

- (void)TCM_setupColorPopUp {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    NSArray *colorNames=[NSArray arrayWithObjects:@"ColorRed",@"ColorOrange",@"ColorYellow",@"ColorGreen",@"ColorTeal",@"ColorBlue",@"ColorPurple",@"ColorPink",nil];
    int colorHues[]={0,3300/360,6600/360,10900/360,18000/360,22800/360,26400/360,31700/360};
    
    [O_colorsPopUpButton removeAllItems];
    
    int i;
    for (i=0;i<(int)[colorNames count];i++) {
        [O_colorsPopUpButton addItemWithTitle:NSLocalizedString([colorNames objectAtIndex:i],@"Color Names")];
        NSMenuItem *item=[O_colorsPopUpButton lastItem];
        [item setImage:[self TCM_menuImageWithColor:[NSColor colorWithCalibratedHue:colorHues[i]/100.
                                saturation:1. brightness:1. alpha:1.]]];
        [item setTag:colorHues[i]];
    }
    [[O_colorsPopUpButton menu] addItem:[NSMenuItem separatorItem]];
    [O_colorsPopUpButton addItemWithTitle:NSLocalizedString(@"ColorCustom",@"Custom Color Name")];

    NSValueTransformer *hueTrans=[NSValueTransformer valueTransformerForName:@"HueToColor"];
    [[O_colorsPopUpButton lastItem] 
        setImage: [self TCM_menuImageWithColor:[hueTrans transformedValue:[defaults objectForKey:CustomMyColorHuePreferenceKey]]]];
    [[O_colorsPopUpButton lastItem] setTag:-1];
    [O_colorsPopUpButton selectItemAtIndex:[defaults integerForKey:SelectedMyColorPreferenceKey]];
}


- (NSImage *)icon {
    return [NSImage imageNamed:@"GeneralPrefs"];
}

- (NSString *)iconLabel {
    return NSLocalizedString(@"GeneralPrefsIconLabel",�@"Label displayed below general icon and used as window title.");
}

- (NSString *)identifier {
    return @"de.codingmonkeys.subethaedit.preferences.general";
}

- (NSString *)mainNibName {
    return @"GeneralPrefs";
}

- (void)mainViewDidLoad {
    // Initialize user interface elements to reflect current preference settings
    [self TCM_setupComboBoxes];
    [self TCM_setupColorPopUp];
    
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    
    TCMMMUser *me=[TCMMMUserManager me];
    [O_pictureImageView setImage:[[me properties] objectForKey:@"Image"]];
    [O_nameTextField setStringValue:[me name]];
    [O_emailComboBox setStringValue:[[me properties] objectForKey:@"Email"]];
    [O_aimComboBox   setStringValue:[[me properties] objectForKey:@"AIM"]];
    [O_modeForNewDocumentsPopUpButton setSelectedModeIdentifier:
        [defaults objectForKey:ModeForNewDocumentsPreferenceKey]];
}

- (void)didUnselect {
    // Save preferences
}

- (void)TCM_updateWells {
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    [defaults setObject:[defaults objectForKey:ChangesSaturationPreferenceKey] forKey:ChangesSaturationPreferenceKey];
    [defaults setObject:[defaults objectForKey:SelectionSaturationPreferenceKey] forKey:SelectionSaturationPreferenceKey];
}

- (IBAction)changeMyCustomColor:(id)aSender {
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    NSValueTransformer *hueTrans=[NSValueTransformer valueTransformerForName:@"HueToColor"];
    NSNumber *hue = (NSNumber *)[hueTrans reverseTransformedValue:[aSender color]];
    [[O_colorsPopUpButton lastItem] 
        setImage: [self TCM_menuImageWithColor:[hueTrans transformedValue:hue]]];

    [defaults setObject:hue
                 forKey:MyColorHuePreferenceKey];
    [defaults setObject:hue
                 forKey:CustomMyColorHuePreferenceKey];
    [[TCMMMUserManager me] setUserHue:hue];
    [TCMMMUserManager didChangeMe];

    [self TCM_updateWells];
}

- (IBAction)changeMyColor:(id)aSender {
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    int tag=[[O_colorsPopUpButton selectedItem] tag];
    NSValueTransformer *hueTrans=[NSValueTransformer valueTransformerForName:@"HueToColor"];
    
    [defaults setObject:[NSNumber numberWithInt:[O_colorsPopUpButton indexOfSelectedItem]]
                 forKey:SelectedMyColorPreferenceKey];

    if (tag==-1) {
        [NSColorPanel setPickerMode:NSHSBModeColorPanel];
        NSColorPanel *panel=[NSColorPanel sharedColorPanel];
        [panel setAction:@selector(changeMyCustomColor:)];
        [panel setTarget:self];
        [panel setShowsAlpha:NO];
        [panel orderFront:self];
        [panel setColor:[hueTrans transformedValue:[defaults objectForKey:CustomMyColorHuePreferenceKey]]];
        tag=(int)([[defaults objectForKey:CustomMyColorHuePreferenceKey] floatValue]);
    } else {
        [[NSColorPanel sharedColorPanel] orderOut:self];
    }

    NSNumber *value=[NSNumber numberWithFloat:(float)tag];
    [defaults setObject:value
                 forKey:MyColorHuePreferenceKey];

    [[TCMMMUserManager me] setUserHue:value];
    [TCMMMUserManager didChangeMe];

    [self TCM_updateWells];
}


@end
