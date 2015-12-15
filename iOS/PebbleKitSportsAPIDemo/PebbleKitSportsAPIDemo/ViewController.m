//
//  ViewController.m
//  PebbleKitSportsAPIDemo
//
//  Created by Chris Lewis on 12/14/15.
//  Copyright © 2015 Pebble. All rights reserved.
//

#import "ViewController.h"

@import PebbleKit;

@interface ViewController () <PBPebbleCentralDelegate>

@property (weak, nonatomic) IBOutlet UIButton *sportsLaunchButton;
@property (weak, nonatomic) IBOutlet UIButton *sportsDummyDataButton;
@property (weak, nonatomic) IBOutlet UISegmentedControl *metricImperialControl;
@property (weak, nonatomic) IBOutlet UISegmentedControl *paceSpeedControl;
@property (weak, nonatomic) IBOutlet UIButton *golfLaunchButton;
@property (weak, nonatomic) IBOutlet UIButton *golfDummyDataButton;
@property PBWatch *watch;
@property PBPebbleCentral *central;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    [PBPebbleCentral setLogLevel:PBPebbleKitLogLevelAll];
    
    // Get the Bluetooth central
    self.central = [PBPebbleCentral defaultCentral];
    
    // Set us as the delegate
    self.central.delegate = self;
    self.central.appUUID = PBSportsUUID;
    
    // Begin communications
    [self.central run];
}

- (void)pebbleCentral:(PBPebbleCentral*)central watchDidConnect:(PBWatch*)watch isNew:(BOOL)isNew {
    NSLog(@"Pebble connected: %@", [watch name]);
    
    // Remember the connected watch
    self.watch = watch;
    
    [self.watch sportsAppAddReceiveUpdateHandler:^BOOL(PBWatch *watch, SportsAppActivityState state) {
        // Display the new state of the watchapp
        switch (state) {
            case SportsAppActivityStateRunning:
                NSLog(@"Watchapp now RUNNING.");
                break;
            case SportsAppActivityStatePaused:
                NSLog(@"Watchapp now PAUSED.");
                break;
            default: break;
        }
        
        // Finally
        return YES;
    }];
}

- (void)pebbleCentral:(PBPebbleCentral*)central watchDidDisconnect:(PBWatch*)watch {
    NSLog(@"Pebble disconnected: %@", [watch name]);
    
    // Remove the disconnected watch
    if ([watch isEqual:self.watch]) {
        self.watch = nil;
    }
}

- (IBAction)sportsLaunchButtonPressed:(id)sender {
    // Launch Sports button pressed
    [self.watch sportsAppLaunch:^(PBWatch * _Nonnull watch, NSError * _Nullable error) {
        NSLog(@"Sports app was launched");
    }];
}

- (IBAction)sportsDummyDataButtonPressed:(id)sender {
    // Send Dummy Data for Sports pressed
    NSDictionary *update = @{ PBSportsTimeKey: @"12:34", PBSportsDistanceKey: @"6.23" };
    [self.watch sportsAppUpdate:update onSent:^(PBWatch * _Nonnull watch, NSError * _Nullable error) {
        if (!error) {
            NSLog(@"Successfully sent message.");
        } else {
            NSLog(@"Error sending message: %@", error);
        }
    }];
}

- (IBAction)metricImperialControlChanged:(id)sender {
    // Metric/Imperial switch was pressed
    NSInteger value = [self.metricImperialControl selectedSegmentIndex];
    BOOL metric = (value == 0);
    
    [self.watch sportsAppSetMetric:metric onSent:^(PBWatch * _Nonnull watch, NSError * _Nonnull error) {
        if (!error) {
            NSLog(@"Successfully sent message.");
        } else {
            NSLog(@"Error sending message: %@", error);
        }
    }];
}

- (IBAction)paceSpeedControlChanged:(id)sender {
    // Pace/Speed switch was pressed
    NSInteger value = self.paceSpeedControl.selectedSegmentIndex;
    BOOL pace = (value == 0);
    
    [self.watch sportsAppSetLabel:pace onSent:^(PBWatch * _Nonnull watch, NSError * _Nullable error) {
        if (!error) {
            NSLog(@"Successfully sent message.");
        } else {
            NSLog(@"Error sending message: %@", error);
        }
    }];
}

- (IBAction)golfLaunchButtonPressed:(id)sender {
    // Launch Golf button pressed
    [self.watch golfAppLaunch:^(PBWatch * _Nonnull watch, NSError * _Nullable error) {
        NSLog(@"Golf app was launched");
    }];
}

- (IBAction)golfDummyDataButtonPressed:(id)sender {
    // Send Dummy Data for Golf was pressed
    NSDictionary *update = @{ PBGolfHoleKey: @"5", PBGolfParKey: @"4",
                              PBGolfBackKey: @"123", PBGolfMidKey: @"456", PBGolfFrontKey: @"789" };
    [self.watch golfAppUpdate:update onSent:^(PBWatch * _Nonnull watch, NSError * _Nullable error) {
        if (!error) {
            NSLog(@"Successfully sent message.");
        } else {
            NSLog(@"Error sending message: %@", error);
        }
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
