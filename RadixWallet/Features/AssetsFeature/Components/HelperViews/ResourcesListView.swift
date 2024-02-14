import SwiftUI

// MARK: - ResourcesListView
public struct ResourcesListView: View {
	public let resources: [CompactResourceView.ViewState]

	public init(resources: [CompactResourceView.ViewState]) {
		self.resources = resources
	}

	public init(fungibles: [CompactFungibleView.ViewState]) {
		self.resources = fungibles.map(CompactResourceView.ViewState.fungible)
	}

	public var body: some View {
		VStack(spacing: 0) {
			ForEach(resources) { resource in
				let isNotLast = resource.id != resources.last?.id
				CompactResourceView(resource: resource)
					.padding(.small1)
					.padding(.bottom, isNotLast ? dividerHeight : 0)
					.overlay(alignment: .bottom) {
						if isNotLast {
							Rectangle()
								.fill(.app.gray3)
								.frame(height: dividerHeight)
						}
					}
			}
		}
		.roundedCorners(strokeColor: .app.gray3)
	}

	private let dividerHeight: CGFloat = 1
}

// MARK: - CompactResourceView
public struct CompactResourceView: View {
	public enum ViewState: Identifiable, Equatable {
		case fungible(CompactFungibleView.ViewState)
		//		case nonFungible(SmallNonfungibleResourceView.ViewState)

		public var id: ResourceAddress {
			switch self {
			case let .fungible(fungible):
				fungible.id
			}
		}
	}

	let resource: ViewState

	public var body: some View {
		switch resource {
		case let .fungible(fungible):
			CompactFungibleView(viewState: fungible)
		}
	}
}

// MARK: - CompactFungibleView
public struct CompactFungibleView: View {
	public struct ViewState: Identifiable, Equatable {
		public var id: ResourceAddress { address }

		public let address: ResourceAddress
		public let title: String?
		public let icon: Thumbnail.FungibleContent
		public let amount: RETDecimal?
		public let fallback: String?

		var amountString: String? {
			amount.map { $0.formatted() } ?? fallback
		}
	}

	public let viewState: ViewState

	public var body: some View {
		HStack(spacing: .zero) {
			Thumbnail(fungible: viewState.icon, size: .smallest)
				.padding(.trailing, .small1)

			if let title = viewState.title {
				Text(title)
					.textStyle(.body2HighImportance)
					.foregroundColor(.app.gray1)
			}

			Spacer(minLength: .small2)

			if let amountString = viewState.amountString {
				Text(amountString)
					.lineLimit(1)
					.minimumScaleFactor(0.8)
					.truncationMode(.tail)
					.textStyle(.secondaryHeader)
					.foregroundColor(.app.gray1)
			}
		}
	}
}

// MARK: - CompactNonfungibleView
public struct CompactNonfungibleView: View {
	public struct ViewState: Identifiable, Equatable {
		public var id: ResourceAddress { address }

		public let address: ResourceAddress
		public let symbol: String?
		public let icon: Thumbnail.FungibleContent
		public let amount: RETDecimal?
		public let fallback: String?

		var amountString: String? {
			amount.map { $0.formatted() } ?? fallback
		}
	}

	public let viewState: ViewState

	public var body: some View {
		HStack(spacing: .zero) {
			Thumbnail(fungible: viewState.icon, size: .smallest)
				.padding(.trailing, .small1)

			if let symbol = viewState.symbol {
				Text(symbol)
					.textStyle(.body2HighImportance)
					.foregroundColor(.app.gray1)
			}

			Spacer(minLength: .small2)

			if let amountString = viewState.amountString {
				Text(amountString)
					.lineLimit(1)
					.minimumScaleFactor(0.8)
					.truncationMode(.tail)
					.textStyle(.secondaryHeader)
					.foregroundColor(.app.gray1)
			}
		}
	}
}
