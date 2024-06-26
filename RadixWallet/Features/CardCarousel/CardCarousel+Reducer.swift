import ComposableArchitecture

// MARK: - CardCarousel
@Reducer
public struct CardCarousel: FeatureReducer {
	@ObservableState
	public struct State: Hashable, Sendable {
		public var cards: [CarouselCard]
		public var taps: Int = 0
	}

	public typealias Action = FeatureAction<Self>

	@CasePathable
	public enum ViewAction: Equatable, Sendable {
		case didAppear
		case didTap(CarouselCard)
	}

	public var body: some ReducerOf<Self> {
		Reduce(core)
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .didAppear:
			print("•• didAppear")
			return .none
		case let .didTap(card):
			state.taps += 1
			print("•• didTap \(state.taps)")
			return .none
		}
	}
}

// MARK: - CarouselCard
public enum CarouselCard: Hashable, Sendable {
	case threeSixtyDegrees
	case connect
	case somethingElse
}

import SwiftUI

// MARK: - CardCarousel.View
extension CardCarousel {
	public struct View: SwiftUI.View {
		let store: StoreOf<CardCarousel>
		@SwiftUI.State private var currentPage: Int = 0

		private var pages: [some SwiftUI.View] {
			store.cards.map { card in
				Button {
					store.send(.view(.didTap(card)))
				} label: {
					Text("\(card.title)")
						.padding(.large2)
						.background(.app.gray5)
						.cornerRadius(.small1)
						.frame(maxWidth: .infinity, alignment: .center)
						.border(.blue)
						.padding(.medium2)
				}
			}
		}

		public var body: some SwiftUI.View {
			WithPerceptionTracking {
				VStack {
					Text("\(store.taps) taps")

					CardCarouselView(pages: pages, currentPage: $currentPage)
						.frame(height: 120)
						.border(.green)
						.padding(.horizontal, .medium2)

					Divider()

					GeometryReader { proxy in
						CarouselView(width: proxy.size.width, cards: store.cards, action: { _ in print("Tap") })
							.frame(height: CarouselCardView.height)
							.border(.red)
							.padding(.horizontal, .large3)
					}

					Divider()
				}
			}
			.padding(.vertical, .small1)
			.onAppear {
				store.send(.view(.didAppear))
			}
		}
	}
}

extension CarouselCard {
	public var title: String {
		switch self {
		case .threeSixtyDegrees:
			"360 Degrees of Security"
		case .connect:
			"Link to connector"
		case .somethingElse:
			"Something Lorem Ipsum"
		}
	}

	public var body: String {
		switch self {
		case .threeSixtyDegrees:
			"Secure your Accounts and Personas with Security shields"
		case .connect:
			"Do it now"
		case .somethingElse:
			"Blabbely bla"
		}
	}

//		public var button: String
//		public var image: ImageAsset
}

// MARK: - CarouselCardView
public struct CarouselCardView: View {
	public static let height: CGFloat = 105
	let card: CarouselCard

	public var body: some SwiftUI.View {
		Text("\(title)")
			.padding(.large2)
			.background(.app.gray5)
			.cornerRadius(.small1)
			.frame(maxWidth: .infinity, alignment: .center)
			.padding(.medium2)
			.border(.blue)
	}

	private var title: String {
		switch card {
		case .threeSixtyDegrees:
			"360 Degrees of Security"
		case .connect:
			"Link to connector"
		case .somethingElse:
			"Something Lorem Ipsum"
		}
	}

	private var message: String {
		switch card {
		case .threeSixtyDegrees:
			"Secure your Accounts and Personas with Security shields"
		case .connect:
			"Do it now"
		case .somethingElse:
			"Blabbely bla"
		}
	}
}

// MARK: - CarouselView
public struct CarouselView: UIViewRepresentable {
	let width: CGFloat
	let cards: [CarouselCard]
	let action: (CarouselCard) -> Void

	private static var cellIdentifier: String { "CarouselCardCell" }

	public func makeUIView(context: Context) -> UICollectionView {
		let layout = UICollectionViewFlowLayout()
		layout.scrollDirection = .vertical
		layout.minimumInteritemSpacing = .small1
		layout.itemSize.width = width
		layout.itemSize.height = 200
		let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
		collectionView.backgroundColor = .clear
		collectionView.isPagingEnabled = true
		collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: Self.cellIdentifier)
		collectionView.delegate = context.coordinator
		collectionView.dataSource = context.coordinator

		return collectionView
	}

	public func updateUIView(_ uiView: UICollectionView, context: Context) {
		uiView.reloadData()
//		if let scrollTarget = scrollTarget.value, let indexPath = context.coordinator.sections.indexPath(for: scrollTarget) {
//			uiView.scrollToRow(at: indexPath, at: .top, animated: false)
//			context.coordinator.didSelectMonth = true
//		}
	}

	public func makeCoordinator() -> Coordinator {
		Coordinator(width: width, cards: cards, action: action)
	}

	public class Coordinator: NSObject, UICollectionViewDelegate, UICollectionViewDataSource {
		let width: CGFloat
		let cards: [CarouselCard]
		let action: (CarouselCard) -> Void

		init(width: CGFloat, cards: [CarouselCard], action: @escaping (CarouselCard) -> Void) {
			self.width = width
			self.cards = cards
			self.action = action
		}

		public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
			cards.count
		}

		public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
			let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CarouselView.cellIdentifier, for: indexPath)
			let card = cards[indexPath.item]

			cell.backgroundColor = .init(.app.gray5)
//			cell.contentView.backgroundColor = .cyan

			cell.contentConfiguration = UIHostingConfiguration {
				CarouselCardView(card: card)
					.border(.yellow)
//				Button {
//					self?.action(.transactionTapped(item.id))
//				} label: {
//					TransactionHistory.TransactionView(transaction: item)
//				}
			}

			return cell
		}

		func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
			CGSize(width: 300, height: 300)
		}

		// UIScrollViewDelegate

		public func scrollViewDidScroll(_ scrollView: UIScrollView) {
			guard let collectionView = scrollView as? UICollectionView else {
				assertionFailure("This should be a UICollectionView")
				return
			}

			let offset = scrollView.contentOffset.y
		}

		public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {}

		public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
			guard let tableView = scrollView as? UITableView else {
				assertionFailure("This should be a UITableView")
				return
			}
		}
	}
}

// MARK: - CardCarouselView
struct CardCarouselView<Page: View>: UIViewControllerRepresentable {
	let pages: [Page]
	@Binding var currentPage: Int

	func makeUIViewController(context: Context) -> UIPageViewController {
		let pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)

		pageViewController.dataSource = context.coordinator
		pageViewController.delegate = context.coordinator
		pageViewController.view.clipsToBounds = false

		return pageViewController
	}

	func updateUIViewController(_ pageViewController: UIPageViewController, context: Context) {
		var direction: UIPageViewController.NavigationDirection = .forward
		var animated = false

		if let previous = pageViewController.viewControllers?.first, let previousPage = context.coordinator.controllers.firstIndex(of: previous) {
			direction = currentPage >= previousPage ? .forward : .reverse
			animated = currentPage != previousPage
		}

		let currentViewController = context.coordinator.controllers[currentPage]
		pageViewController.setViewControllers([currentViewController], direction: direction, animated: animated)
	}

	func makeCoordinator() -> Coordinator {
		Coordinator(parent: self, pages: pages)
	}

	class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
		let parent: CardCarouselView
		let controllers: [UIViewController]

		init(parent: CardCarouselView, pages: [Page]) {
			self.parent = parent
			self.controllers = pages.map {
				let hostingController = UIHostingController(rootView: $0)
				hostingController.view.backgroundColor = .clear
				hostingController.view.clipsToBounds = false
				return hostingController
			}
		}

		func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
			guard let index = controllers.firstIndex(of: viewController) else {
				return nil
			}
			if index == 0 {
				return nil
			}
			return controllers[index - 1]
		}

		func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
			guard let index = controllers.firstIndex(of: viewController) else {
				return nil
			}
			if index + 1 == controllers.count {
				return nil
			}
			return controllers[index + 1]
		}

		func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
			if completed, let currentViewController = pageViewController.viewControllers?.first, let currentIndex = controllers.firstIndex(of: currentViewController) {
				parent.currentPage = currentIndex
			}
		}
	}
}
