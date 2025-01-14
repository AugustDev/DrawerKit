import UIKit

extension PresentationController {
    var containerViewBounds: CGRect {
        return containerView?.bounds ?? .zero
    }

    var containerViewSize: CGSize {
        return containerViewBounds.size
    }

    var containerViewHeight: CGFloat {
        return containerViewSize.height
    }

    var drawerFullY: CGFloat {
        return (presentedViewController as? DrawerPresentable)?.fullExpansionBehaviour?.drawerFullY
            ?? configuration.fullExpansionBehaviour.drawerFullY
    }

    var drawerPartialHeight: CGFloat {
        guard let presentedVC = presentedViewController as? DrawerPresentable else { return 0 }
        let drawerPartialH = presentedVC.heightOfPartiallyExpandedDrawer
        return GeometryEvaluator.drawerPartialH(drawerPartialHeight: drawerPartialH,
                                                containerViewHeight: containerViewHeight)
    }

    var drawerPartialY: CGFloat {
        return GeometryEvaluator.drawerPartialY(drawerPartialHeight: drawerPartialHeight,
                                                containerViewHeight: containerViewHeight)
    }

    var drawerCollapsedHeight: CGFloat {
        guard let presentedVC = presentedViewController as? DrawerPresentable else { return 0 }
        let drawerCollapsedH = presentedVC.heightOfCollapsedDrawer
        return GeometryEvaluator.drawerCollapsedH(drawerCollapsedHeight: drawerCollapsedH,
                                                  containerViewHeight: containerViewHeight)
    }

    var drawerCollapsedY: CGFloat {
        return GeometryEvaluator.drawerCollapsedY(drawerCollapsedHeight: drawerCollapsedHeight,
                                                containerViewHeight: containerViewHeight)
    }

    var upperMarkY: CGFloat {
        return GeometryEvaluator.upperMarkY(drawerFullY: drawerFullY,
                                            drawerPartialHeight: drawerPartialHeight,
                                            containerViewHeight: containerViewHeight,
                                            configuration: configuration)
    }

    var lowerMarkY: CGFloat {
        return GeometryEvaluator.lowerMarkY(drawerPartialHeight: drawerPartialHeight,
                                            containerViewHeight: containerViewHeight,
                                            configuration: configuration)
    }

    var currentDrawerState: DrawerState {
        get {
            return GeometryEvaluator.drawerState(for: currentDrawerY,
                                                 drawerFullY: drawerFullY,
                                                 drawerCollapsedHeight: drawerCollapsedHeight,
                                                 drawerPartialHeight: drawerPartialHeight,
                                                 containerViewHeight: containerViewHeight,
                                                 configuration: configuration)
        }

        set {
            currentDrawerY =
                GeometryEvaluator.drawerPositionY(for: newValue,
                                                  drawerCollapsedHeight: drawerCollapsedHeight,
                                                  drawerPartialHeight: drawerPartialHeight,
                                                  containerViewHeight: containerViewHeight,
                                                  drawerFullY: drawerFullY)
        }
    }

    var currentDrawerY: CGFloat {
        get {
            let posY = presentedView?.frame.origin.y ?? drawerFullY
            return min(max(posY, drawerFullY), containerViewHeight)
        }

        set {
            let posY = min(max(newValue, drawerFullY), containerViewHeight)
            presentedView?.frame.origin.y = posY

            if let backgroundView = backgroundView,
                let handle = configuration.drawerBackgroundConfiguration?.handle {

                let context = DrawerBackgroundConfiguration.HandleContext(currentY: posY, containerHeight: containerViewHeight)
                handle(backgroundView, context)
            }
        }
    }

    var currentDrawerCornerRadius: CGFloat {
        get {
            let radius = presentedView?.layer.cornerRadius ?? 0
            return min(max(radius, 0), maximumCornerRadius)
        }

        set {
            let update = {
                let radius = min(max(newValue, 0), self.maximumCornerRadius)
                self.presentedView?.layer.cornerRadius = radius
                self.presentedView?.layer.masksToBounds = true
                if #available(iOS 11.0, *) {
                    self.presentedView?.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
                }
            }
            if self.configuration.cornerAnimationOption == .none {
                UIView.performWithoutAnimation(update)
            } else {
                update()
            }
        }
    }

    func cornerRadius(at state: DrawerState) -> CGFloat {
        switch configuration.cornerAnimationOption {
        case .none:
            return maximumCornerRadius
        case .maximumAtPartialY:
            return maximumCornerRadius * triangularValue(at: state)
        case .alwaysShowBelowStatusBar:
            let positionY = GeometryEvaluator.drawerPositionY(
                for: state,
                drawerCollapsedHeight: drawerCollapsedHeight,
                drawerPartialHeight: drawerPartialHeight,
                containerViewHeight: containerViewHeight,
                drawerFullY: drawerFullY
            )

            return maximumCornerRadius * min(positionY, DrawerGeometry.statusBarHeight) / DrawerGeometry.statusBarHeight
        }
    }

    func handleViewAlpha(at state: DrawerState) -> CGFloat {
        return triangularValue(at: state)
    }

    private func triangularValue(at state: DrawerState) -> CGFloat {
        guard drawerPartialY != drawerFullY
            && drawerPartialY != containerViewHeight
            && drawerFullY != containerViewHeight
            else { return 0 }

        let positionY =
            GeometryEvaluator.drawerPositionY(for: state,
                                              drawerCollapsedHeight: drawerCollapsedHeight,
                                              drawerPartialHeight: drawerPartialHeight,
                                              containerViewHeight: containerViewHeight,
                                              drawerFullY: drawerFullY)

        let fraction: CGFloat
        if supportsPartialExpansion {
            if positionY < drawerPartialY {
                fraction = (positionY - drawerFullY) / (drawerPartialY - drawerFullY)
            } else {
                fraction = 1 - (positionY - drawerPartialY) / (containerViewHeight - drawerPartialY)
            }
        } else {
            fraction = 1 - (positionY - drawerFullY) / (containerViewHeight - drawerFullY)
        }

        return fraction
    }
}
