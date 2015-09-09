#import <UIKit/UIKit.h>
#import <CaptainHook/CaptainHook.h>

@class SBIcon;

@interface SBIconViewMap : NSObject
- (UIView *)iconViewForIcon:(SBIcon *)icon;
@end

@interface SBIconListView : UIView
- (SBIconViewMap *)viewMap;
- (NSArray *)visibleIcons;
@end

@interface SBFolderController : NSObject
- (UIView *)contentView;
- (SBIconListView *)currentIconListView;
- (SBIconListView *)dockListView;
@end

@interface SBRootFolderController : SBFolderController
@end

@interface SBIconController : NSObject
+ (SBIconController *)sharedInstance;
- (UIView *)contentView;
- (SBRootFolderController *)_rootFolderController;
@end

%hook SBSearchGesture

- (id)init
{
	if ((self = %orig())) {
		UIPanGestureRecognizer **_panGestureRecognizer = CHIvarRef(self, _panGestureRecognizer, UIPanGestureRecognizer *);
		if (_panGestureRecognizer) {
			[*_panGestureRecognizer addTarget:self action:@selector(glance_panGestureRecognizer:)];
		}
	}
	return self;
}

static CGFloat clamped(CGFloat value)
{
	if (value < 0.0)
		return 0.0;
	if (value > 1.0)
		return 1.0;
	return value;
}

static NSMutableSet *views;

static void updateViewForOffset(UIView *view, CGFloat offset)
{
	UIView *containerView = view.window.rootViewController.view;
	CGFloat containerHeight = [%c(SBIconController) sharedInstance].contentView.bounds.size.height;
	CGFloat centerPosition = [view.superview convertPoint:view.center toView:containerView].y;
	CGFloat inverseAlpha = (offset + clamped(1.0 - centerPosition / containerHeight) * 200.0) * (-1.0 / 75.0);
	view.alpha = 1.0 - clamped(inverseAlpha);
	if (!views) {
		views = [[NSMutableSet alloc] init];
	}
	[views addObject:view];
}

static CGFloat baseOffset;

static void updateForOffset(CGFloat offset)
{
	offset += baseOffset;
	SBRootFolderController *rootController = [%c(SBIconController) sharedInstance]._rootFolderController;
	SBIconListView *listView = rootController.currentIconListView;
	SBIconViewMap *viewMap = listView.viewMap;
	for (SBIcon *icon in listView.visibleIcons) {
		updateViewForOffset([viewMap iconViewForIcon:icon], offset);
	}
	updateViewForOffset(rootController.dockListView.superview, offset);
	UIPageControl **_pageControl = CHIvarRef(rootController.contentView, _pageControl, UIPageControl *);
	if (_pageControl) {
		for (UIView *subview in [*_pageControl subviews]) {
			updateViewForOffset(subview, offset);
		}
	}
}

%new
- (void)glance_panGestureRecognizer:(UIPanGestureRecognizer *)recognizer
{
	CGFloat offset = [recognizer translationInView:recognizer.view].y;
	updateForOffset(offset);
	if (recognizer.state == UIGestureRecognizerStateEnded) {
		baseOffset += offset;
		if (baseOffset < -400) {
			baseOffset = -400;
		} else if (baseOffset > 0) {
			baseOffset = 0;
		}
	}
}

%end

%hook SBSearchScrollView

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)recognizer
{
	%orig();
	return YES;
}

%end

static void ResetStyle(void)
{
	if ([views anyObject]) {
		[UIView animateWithDuration:0.333 delay:0.0 options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState animations:^{
			baseOffset = 0.0;
			for (UIView *view in [views allObjects]) {
				view.alpha = 1.0;
			}
			[views removeAllObjects];
		} completion:NULL];
	}
}

%hook SBRootFolderView

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
	ResetStyle();
	%orig();
}

%end

%hook SBUIController

- (BOOL)clickedMenuButton
{
	ResetStyle();
	return %orig();
}

%end
