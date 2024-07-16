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
		HStack(alignment: kind.verticalAlignment, spacing: .zero) {
			switch kind.axis {
			case .horizontal:
				horizontalCore
			case .vertical:
				verticalCore
			}
			Spacer(minLength: .zero)
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
		/// Stacks the name and address horizontally
		/// When `addCornerRadius`, its shaped is clipped with a corner radius of 12.
		/// Used for example in Account Settings view.
		case display(addCornerRadius: Bool)

		/// Similar to `regular`, but with a smaller vertical padding.
		/// Used for example in Customize Fees view.
		case compact(addCornerRadius: Bool)

		/// Stacks the name and address vertically, while expecting more content in the trailing and bottom sections.
		/// Its shape is clipped with a corner radius of 12.
		/// Used for Home rows.
		case home(tag: String?)
	}
}

extension AccountCard.Kind {
	/// A standard `.display` with corner radius added.
	static var display: Self {
		.display(addCornerRadius: true)
	}

	/// A standard `.compact` with corner radius added.
	static var compact: Self {
		.compact(addCornerRadius: true)
	}

	/// A `.compact` without corner radius, since it is part of an `InnerCard`.
	static var innerCompact: Self {
		.compact(addCornerRadius: false)
	}
}

private extension AccountCard.Kind {
	var axis: Axis {
		switch self {
		case .display, .compact:
			.horizontal
		case .home:
			.vertical
		}
	}

	var verticalAlignment: VerticalAlignment {
		switch self {
		case .compact, .display:
			.center
		case .home:
			.top
		}
	}

	var horizontalPadding: CGFloat {
		switch self {
		case .display, .compact:
			.medium3
		case .home:
			.medium1
		}
	}

	var verticalPadding: CGFloat {
		switch self {
		case .home, .display:
			.medium2
		case .compact:
			.small1
		}
	}

	var cornerRadius: CGFloat {
		switch self {
		case let .display(addCornerRadius), let .compact(addCornerRadius):
			addCornerRadius ? .small1 : .zero
		case .home:
			.small1
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
