//
//  ViewController.m
//  PebbleKitSportsAPIDemo
//
//  Created by Chris Lewis on 12/14/15.
//  Copyright © 2015 Pebble. All rights reserved.
//

#import "ViewController.h"

@import PebbleKit;

typedef NS_ENUM(NSInteger, PaceSpeedControlIndex) {
  PaceSpeedControlIndexPace = 0,
  PaceSpeedControlIndexSpeed = 1,
};

typedef NS_ENUM(NSUInteger, UnitSystemControlIndex) {
  UnitSystemControlIndexImperial,
  UnitSystemControlIndexMetric,
};

@interface ViewController () <PBPebbleCentralDelegate>

@property (weak, nonatomic) IBOutlet UIButton *sportsLaunchButton;
@property (weak, nonatomic) IBOutlet UIButton *sportsDummyDataButton;
@property (weak, nonatomic) IBOutlet UISegmentedControl *metricImperialControl;
@property (weak, nonatomic) IBOutlet UISegmentedControl *paceSpeedControl;
@property (weak, nonatomic) IBOutlet UIButton *golfLaunchButton;
@property (weak, nonatomic) IBOutlet UIButton *golfDummyDataButton;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;

@property (nonatomic) PBWatch *watch;
@property (nonatomic) PBPebbleCentral *central;

@property (nonatomic) PBSportsUpdate *sportsUpdate;
@property (nonatomic) NSTimer *updateTimer;

@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  // [PBPebbleKitLogging setLogLevel:PBPebbleKitLogLevelAll];

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
        self.statusLabel.text = @"Watchapp now running.";
        break;
      case SportsAppActivityStatePaused:
        self.statusLabel.text = @"Watchapp now paused.";
        break;
      default: break;
    }

    // Finally
    return YES;
  }];
}

- (void)pebbleCentral:(PBPebbleCentral *)central watchDidDisconnect:(PBWatch *)watch {
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
  if (self.updateTimer) {
    [self.updateTimer invalidate];
    self.updateTimer = nil;
  }

  NSTimeInterval startTime = [NSDate timeIntervalSinceReferenceDate];
  self.sportsUpdate = [[PBSportsUpdate alloc] init];
  self.sportsUpdate.customLabel = @"Accel (in mG)";
  [self updateSportsUpdateWithTime:0];

  self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:1 repeats:YES block:^(NSTimer * _Nonnull timer) {
    NSTimeInterval currentTime = [NSDate timeIntervalSinceReferenceDate] - startTime;
    [self updateSportsUpdateWithTime:currentTime];
    [self.sportsUpdate updateWatch:self.watch completion:^(NSError * _Nullable error) {
      if (!error) {
        NSLog(@"Successfully sent message.");
      } else {
        NSLog(@"Error sending message: %@", error);
      }
    }];
  }];
}

- (IBAction)metricImperialControlChanged:(id)sender {
  // Metric/Imperial switch was pressed
  UnitSystemControlIndex value = [self.metricImperialControl selectedSegmentIndex];
  PBUnitSystem unitSystem = value == UnitSystemControlIndexMetric ? PBUnitSystemMetric : PBUnitSystemImperial;

  [self.watch sportsAppSetUnitSystem:unitSystem onSent:^(PBWatch * _Nonnull watch, NSError * _Nonnull error) {
    if (!error) {
      NSLog(@"Successfully sent message.");
    } else {
      NSLog(@"Error sending message: %@", error);
    }
  }];
}

- (IBAction)paceSpeedControlChanged:(id)sender {
  // Pace/Speed switch was pressed. Since we update every second with the timer
  // we don't need to do anything here. Next update will have the right value.
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

- (void)updateSportsUpdateWithTime:(NSTimeInterval)time {
  self.sportsUpdate.time = time;

  // The distance is an always increasing value with a little variability.
  // The rest of the values are derivatives of this function, which I hope my
  // physics professor will approve.
  self.sportsUpdate.distance = (1.5 * time + sin(time/10)) / 1000;

  PaceSpeedControlIndex value = self.paceSpeedControl.selectedSegmentIndex;
  if (value == PaceSpeedControlIndexPace) {
    self.sportsUpdate.pace = (10 / (15 + cos(time/10))) * 1000;
  } else {
    self.sportsUpdate.speed = (15 + cos(time/10))/10 * (3600/1000);
  }

  self.sportsUpdate.heartRate = 90 + sin(time/10) * 30;

  double accel = fabs(-0.01 * sin(time/10) * 102); // m/s^2 -> mG
  NSString *accelString = [NSString stringWithFormat:@"%0.3f", accel];
  self.sportsUpdate.customValue = accelString;
}

@end
