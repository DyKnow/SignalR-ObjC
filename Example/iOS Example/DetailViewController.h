//
//  DetailViewController.h
//  iOS Example
//
//  Created by Alex Billingsley on 3/1/16.
//
//

#import <UIKit/UIKit.h>

@interface DetailViewController : UIViewController

@property (strong, nonatomic) id detailItem;
@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;

@end

