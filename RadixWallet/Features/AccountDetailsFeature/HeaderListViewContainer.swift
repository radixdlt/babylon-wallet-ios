import SwiftUI
import SwiftUIIntrospect

/**
 A component that creates a collapsible header with a list.

 This `HeaderListViewContainer` struct is a `UIViewRepresentable` wrapper for combining a header view and a list view.

 - Parameters:
    - Header: A `View` representing the header.
    - List: A `View` representing the list.

 This component dynamically adjusts the layout based on the scroll position of the list. As the user scrolls, the header collapses and fades out, providing a smooth transition effect.

 - Note: This component relies on the Introspect library for UIKit introspection.
 */
public struct HeaderListViewContainer<Header: View, List: View>: UIViewRepresentable {
	public typealias UIViewType = UIView

	private let headerView: Header
	private let listView: List

	@State private var observation: NSKeyValueObservation?

	public init(
		@ViewBuilder headerView: () -> Header,
		@ViewBuilder listView: () -> List
	) {
		self.headerView = headerView()
		self.listView = listView()
	}

	public func makeUIView(context: Context) -> UIView {
		let containerView = UIView()
		addSubviews(in: containerView)

		return containerView
	}

	public func updateUIView(_ uiView: UIViewType, context: Context) {
		uiView.subviews.forEach { $0.removeFromSuperview() }
		addSubviews(in: uiView)
	}

	@MainActor
	private func addSubviews(in view: UIView) {
		var topConstraint: NSLayoutConstraint!
		var initialTopInset: CGFloat = 0
		let headerController = UIHostingController(
			rootView: self.headerView
				.introspect(.view, on: .iOS(.v16, .v17)) { view in
					initialTopInset = view.frame.height
					topConstraint.constant = view.frame.height
				}
		)

		guard let headerView = headerController.view else { return }

		let listController = UIHostingController(
			rootView: self.listView
				.introspect(.list, on: .iOS(.v16, .v17)) { tableView in
					observation = tableView.observe(\.contentOffset) { tableView, _ in
						DispatchQueue.main.async {
							let offset = tableView.contentOffset.y

							/// Threshold to avoid setting constraints too frequently
							let offsetThreshold: CGFloat = 0.5

							if abs(offset) > offsetThreshold {
								topConstraint.constant = min(max(0, topConstraint.constant - offset), headerView.bounds.height)
							}

							/// Reset `contentOffset` in order to avoid scroll when `listView` is not fully expanded
							let shouldResetOffset = topConstraint.constant > 0
								&& topConstraint.constant < headerView.bounds.height
								&& abs(offset) > offsetThreshold
							if shouldResetOffset {
								tableView.contentOffset.y = 0
							}

							/// Set header alpha
							var headerAlpha = 1 - (initialTopInset - topConstraint.constant) / initialTopInset

							/// Make transition more prominent
							if headerAlpha < 1 {
								headerAlpha -= 0.3
							}

							headerView.alpha = max(0, min(headerAlpha, 1))
						}
					}
				}
		)

		guard let listView = listController.view else { return }

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
		topConstraint = listView.topAnchor.constraint(equalTo: view.topAnchor, constant: headerView.bounds.height)
		topConstraint.isActive = true
		NSLayoutConstraint.activate([
			listView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
			listView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
			listView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
		])
	}
}
