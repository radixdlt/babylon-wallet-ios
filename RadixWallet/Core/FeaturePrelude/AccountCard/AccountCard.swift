import SwiftUI

// MARK: - AccountCard
struct AccountCard<Trailing: View, Bottom: View>: View {
	let kind: Kind
	let account: AccountCardDataSource
	let trailing: Trailing
	let bottom: Bottom

	init(
		kind: Kind,
		account: AccountCardDataSource,
		@ViewBuilder trailing: () -> Trailing,
		@ViewBuilder bottom: () -> Bottom
	) {
		self.kind = kind
		self.account = account
		self.trailing = trailing()
		self.bottom = bottom()
	}

	public var body: some View {
		VStack(spacing: .zero) {
			top
			bottom
		}
		.padding(.vertical, kind.verticalPadding)
		.padding(.horizontal, kind.horizontalPadding)
		.background {
			LinearGradient(gradient: account.gradient, startPoint: .leading, endPoint: .trailing)
		}
		.clipShape(RoundedRectangle(cornerRadius: kind.cornerRadius))
	}
}

@MainActor
extension AccountCard {
	private var top: some View {
		HStack(alignment: .top, spacing: .zero) {
			switch kind.axis {
			case .horizontal:
				horizontalCore
			case .vertical:
				verticalCore
			}
			Spacer()
			trailing
		}
	}

	private var horizontalCore: some View {
		HStack(spacing: .zero) {
			if let title = account.title {
				Text(title)
					.foregroundColor(.app.white)
					.textStyle(.body1Header)

				Spacer(minLength: .zero)

				addressView
			} else {
				Spacer()
				addressView
				Spacer()
			}
		}
	}

	private var verticalCore: some View {
		VStack(alignment: .leading, spacing: .small2) {
			Text(account.title)
				.foregroundColor(.app.white)
				.textStyle(.body1Header)

			addressView
		}
	}

	private var addressView: some View {
		HStack(spacing: .small3) {
			AddressView(account.ledgerIdentifiable)

			if let tag = kind.tag {
				Text("•")
				Text(tag)
			}
		}
		.foregroundColor(.app.whiteTransparent)
		.textStyle(.body2HighImportance)
	}
}

// MARK: AccountCard.Kind
extension AccountCard {
	public enum Kind {
		/// Stacks the name and address horizontally, in a rounded rectangle shape with corner radius 12.
		/// Used for example in Account Settings view.
		case display

		/// Similar to `regular`, but with a smaller vertical padding.
		/// Used for example in Customize Fees view.
		case compact

		/// Similar to `compact`, but without any corner radius on its shape.
		case innerCompact

		/// Stacks the name and address vertically, while expecting more content in the trailing and bottom sections.
		/// Used for Home rows.
		case home(tag: String?)
	}
}

private extension AccountCard.Kind {
	var axis: Axis {
		switch self {
		case .display, .compact, .innerCompact:
			.horizontal
		case .home:
			.vertical
		}
	}

	var horizontalPadding: CGFloat {
		switch self {
		case .display, .compact, .innerCompact:
			.medium3
		case .home:
			.medium1
		}
	}

	var verticalPadding: CGFloat {
		switch self {
		case .home, .display:
			.medium2
		case .compact, .innerCompact:
			.small1
		}
	}

	var cornerRadius: CGFloat {
		switch self {
		case .display, .compact, .home:
			.small1
		case .innerCompact:
			.zero
		}
	}

	var tag: String? {
		switch self {
		case let .home(tag):
			tag
		default:
			nil
		}
	}
}
