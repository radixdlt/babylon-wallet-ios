import SwiftUI
@_spi(Advanced) import SwiftUIIntrospect

/**
 A component that creates a collapsible header with a list.

 This `HeaderListViewContainer` struct is a `UIViewRepresentable` wrapper for combining a header view and a list view.

 - Parameters:
    - Header: A `View` representing the header.
    - List: A `View` representing the list.

 This component dynamically adjusts the layout based on the scroll position of the list. As the user scrolls, the header collapses and fades out, providing a smooth transition effect.

 - Note: This component relies on the Introspect library for UIKit introspection.
 */
struct HeaderListViewContainer<Header: View, List: View>: UIViewRepresentable {
	typealias UIViewType = UIView

	private let headerView: Header
	private let listView: List

	@State private var observation: NSKeyValueObservation?

	init(
		@ViewBuilder headerView: () -> Header,
		@ViewBuilder listView: () -> List
	) {
		self.headerView = headerView()
		self.listView = listView()
	}

	func makeUIView(context: Context) -> UIView {
		let containerView = UIView()
		addSubviews(in: containerView, context: context)

		return containerView
	}

	func updateUIView(_ uiView: UIViewType, context: Context) {
		context.coordinator.headerController.rootView = AnyView(
			headerView
				.onSizeChanged { size in
					context.coordinator.initialTopInset = size.height
					context.coordinator.topConstraint?.constant = size.height
				}
		)
		context.coordinator.headerController.view.setNeedsUpdateConstraints()

		context.coordinator.listController.rootView = AnyView(
			listView
				.introspect(.list, on: .iOS(.v16...)) { tableView in
					observation = tableView.observe(\.contentOffset) { tableView, _ in
						DispatchQueue.main.async {
							guard
								!context.coordinator.isAnimating,
								let topConstraint = context.coordinator.topConstraint
							else { return }

							let initialTopInset = context.coordinator.initialTopInset
							let headerHeight = context.coordinator.headerController.view.bounds.height
							let offset = tableView.contentOffset.y

							/// Threshold to avoid setting constraints too frequently
							let offsetThreshold: CGFloat = 0.5

							if abs(offset) > offsetThreshold {
								topConstraint.constant = min(max(0, topConstraint.constant - offset), headerHeight)
							} else {
								/// Threshold to control scroll sensitivity
								let velocityThreshold: Double = 900
								let velocity = tableView.panGestureRecognizer.velocity(in: tableView.superview).y

								let shouldScrollUp = velocity < -velocityThreshold && topConstraint.constant > 0
								let shouldScrollDown = velocity > velocityThreshold && topConstraint.constant < initialTopInset

								/// Update the list view's top constraint animated
								if shouldScrollUp || shouldScrollDown {
									let newTopConstraintConstant = shouldScrollUp ? 0 : initialTopInset
									topConstraint.constant = newTopConstraintConstant

									/// Extend the list view's height to prevent it from shrinking mid-animation
									if shouldScrollDown {
										context.coordinator.bottomConstraint?.constant = context.coordinator.listController.view.bounds.height
									}

									context.coordinator.isAnimating = true
									tableView.isScrollEnabled = false
									UIView.animate(withDuration: 0.3, animations: {
										context.coordinator.headerController.view.superview?.layoutIfNeeded()
									}, completion: { _ in
										context.coordinator.isAnimating = false
										tableView.isScrollEnabled = true
										context.coordinator.bottomConstraint?.constant = 0
									})
								}
							}

							/// Reset `contentOffset` in order to avoid scroll when `listView` is not fully expanded
							let shouldResetOffset = topConstraint.constant > 0
								&& topConstraint.constant < headerHeight
								&& abs(offset) > offsetThreshold
							if shouldResetOffset {
								tableView.contentOffset.y = 0
							}

							/// Set header alpha
							var headerAlpha = 1 - (initialTopInset - topConstraint.constant) / initialTopInset

							/// Make transition more prominent
							if headerAlpha < 1 {
								headerAlpha -= 0.2
							}

							context.coordinator.headerController.view.alpha = max(0, min(headerAlpha, 1))
						}
					}
				}
		)
		context.coordinator.listController.view.setNeedsUpdateConstraints()
	}

	func makeCoordinator() -> Coordinator {
		Coordinator(
			headerController: UIHostingController(rootView: AnyView(headerView)),
			listController: UIHostingController(rootView: AnyView(listView))
		)
	}

	class Coordinator: NSObject {
		var topConstraint: NSLayoutConstraint?
		var bottomConstraint: NSLayoutConstraint?
		var initialTopInset: CGFloat = 0
		var isAnimating = false
		var headerController: UIHostingController<AnyView>
		var listController: UIHostingController<AnyView>

		init(
			headerController: UIHostingController<AnyView>,
			listController: UIHostingController<AnyView>
		) {
			self.headerController = headerController
			self.listController = listController
		}
	}

	@MainActor
	private func addSubviews(in view: UIView, context: Context) {
		guard
			let headerView = context.coordinator.headerController.view,
			let listView = context.coordinator.listController.view
		else { return }

		headerView.backgroundColor = .clear
		listView.backgroundColor = .clear

		view.addSubview(headerView)
		view.addSubview(listView)

		headerView.translatesAutoresizingMaskIntoConstraints = false
		NSLayoutConstraint.activate([
			headerView.topAnchor.constraint(equalTo: view.topAnchor),
			headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
			headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
		])

		listView.translatesAutoresizingMaskIntoConstraints = false
		context.coordinator.topConstraint = listView.topAnchor.constraint(equalTo: view.topAnchor, constant: headerView.bounds.height)
		context.coordinator.topConstraint?.isActive = true
		context.coordinator.bottomConstraint = listView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
		context.coordinator.bottomConstraint?.isActive = true
		NSLayoutConstraint.activate([
			listView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
			listView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
		])
	}
}
