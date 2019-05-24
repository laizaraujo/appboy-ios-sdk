#import "ABKCaptionedImageContentCardCell.h"
#import <SDWebImage/UIImageView+WebCache.h>

static const CGFloat ImageMinResizingDifference = 5e-1;

@implementation ABKCaptionedImageContentCardCell

- (void)prepareForReuse {
  [super prepareForReuse];
  [self.captionedImageView sd_cancelCurrentAnimationImagesLoad];
}

- (void)hideLinkLabel:(BOOL)hide {
  self.linkLabel.hidden = hide;
  if (hide) {
    if ((self.linkBottomConstraint.priority != UILayoutPriorityDefaultLow)
        || (self.descriptionBottomConstraint.priority != UILayoutPriorityDefaultHigh)) {
      self.linkBottomConstraint.priority = UILayoutPriorityDefaultLow;
      self.descriptionBottomConstraint.priority = UILayoutPriorityDefaultHigh;
      [self setNeedsLayout];
    }
  } else {
    if ((self.linkBottomConstraint.priority != UILayoutPriorityDefaultHigh)
        || (self.descriptionBottomConstraint.priority != UILayoutPriorityDefaultLow)) {
      self.linkBottomConstraint.priority = UILayoutPriorityDefaultHigh;
      self.descriptionBottomConstraint.priority = UILayoutPriorityDefaultLow;
      [self setNeedsLayout];
    }
  }
}

- (void)applyCard:(ABKCaptionedImageContentCard *)captionedImageCard {
  if (![captionedImageCard isKindOfClass:[ABKCaptionedImageContentCard class]]) {
    return;
  }
  
  [super applyCard:captionedImageCard];
  
  [self applyAppboyAttributedTextStyleFrom:captionedImageCard.title forLabel:self.titleLabel];
  [self applyAppboyAttributedTextStyleFrom:captionedImageCard.cardDescription forLabel:self.descriptionLabel];
  [self applyAppboyAttributedTextStyleFrom:captionedImageCard.domain forLabel:self.linkLabel];
  
  BOOL shouldHideLink = (captionedImageCard.domain.length == 0);
  [self hideLinkLabel:shouldHideLink];
  
  CGFloat currImageHeightConstraint = self.captionedImageView.frame.size.width / captionedImageCard.imageAspectRatio;
  if ([self shouldResizeImageWithNewConstant:currImageHeightConstraint]) {
    [self updateImageConstraintsWithNewConstant:currImageHeightConstraint];
  }
  
  typeof(self) __weak weakSelf = self;
  [self.captionedImageView sd_setImageWithURL:[NSURL URLWithString:captionedImageCard.image] placeholderImage:nil options:(SDWebImageQueryDataWhenInMemory | SDWebImageQueryDiskSync) completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
    if (weakSelf == nil) {
      return;
    }
    if (image && image.size.width > 0.0) {
      dispatch_async(dispatch_get_main_queue(), ^{
        CGFloat newImageAspectRatio = image.size.width / image.size.height;
        CGFloat newImageHeightConstraint = weakSelf.captionedImageView.frame.size.width / newImageAspectRatio;
        if ([self shouldResizeImageWithNewConstant:newImageHeightConstraint]) {
          // Update image size based on actual downloaded image
          [weakSelf updateImageConstraintsWithNewConstant:newImageHeightConstraint];
          [weakSelf.delegate refreshTableViewCellHeights];
          captionedImageCard.imageAspectRatio = newImageAspectRatio;
        }
      });
    } else {
      dispatch_async(dispatch_get_main_queue(), ^{
        weakSelf.captionedImageView.image = [weakSelf getPlaceHolderImage];
      });
    }
  }];
}

- (void)updateImageConstraintsWithNewConstant:(CGFloat)newConstant {
  self.imageHeightContraint.constant = newConstant;
  [self setNeedsLayout];
}

#pragma mark - Private methods

- (BOOL)shouldResizeImageWithNewConstant:(CGFloat)newConstant {
  return self.imageHeightContraint &&
      fabs(newConstant - self.imageHeightContraint.constant) > ImageMinResizingDifference;
}

@end
