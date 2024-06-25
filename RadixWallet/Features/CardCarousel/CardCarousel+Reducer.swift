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

// MARK: - CardCarouselView
struct CardCarouselView<Page: View>: UIViewControllerRepresentable {
	let pages: [Page]
	@Binding var currentPage: Int

	func makeUIViewController(context: Context) -> UIPageViewController {
		let pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)

		pageViewController.dataSource = context.coordinator
		pageViewController.delegate = context.coordinator

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
		var parent: CardCarouselView
		var controllers: [UIViewController]

		init(parent: CardCarouselView, pages: [Page]) {
			self.parent = parent
			self.controllers = pages.map {
				let hostingController = UIHostingController(rootView: $0)
				hostingController.view.backgroundColor = .clear
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
