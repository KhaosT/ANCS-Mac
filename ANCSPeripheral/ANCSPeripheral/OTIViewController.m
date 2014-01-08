//
//  OTIViewController.m
//  ANCSPeripheral
//
//  Created by Khaos Tian on 12/30/13.
//  Copyright (c) 2013 Oltica. All rights reserved.
//

#import "OTIViewController.h"
#import "OTIANCSCore.h"

@interface OTIViewController ()
{
    OTIANCSCore *_ancsCore;
}

@end

@implementation OTIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    _ancsCore = [[OTIANCSCore alloc]init];
    [_ancsCore setupANCS];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
