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

	var body: some View {
		VStack(spacing: .zero) {
			top
			bottom
		}
		.padding(.vertical, kind.verticalPadding)
		.padding(.horizontal, kind.horizontalPadding)
		.background {
			LinearGradient(gradient: account.gradient, startPoint: .leading, endPoint: .trailing)
				.brightness(kind.gradientBrightness)
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
					.foregroundColor(.white)
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
				.foregroundColor(.white)
				.textStyle(.body1Header)

			addressView
		}
	}

	private var addressView: some View {
		HStack(spacing: .small3) {
			AddressView(account.ledgerIdentifiable)

			ForEach(kind.tag, id: \.self) { tag in
				Text("•")
				Text(tag.display)
				if case let .factorSource(fs) = tag {
					Image(fs.kind.icon)
						.resizable()
						.frame(.icon)
				}
			}
		}
		.foregroundColor(.app.whiteTransparent)
		.textStyle(.body2HighImportance)
	}
}

enum AccountCardTag: Hashable, Sendable {
	case legacy
	case dAppDefinition
	case factorSource(FactorSource)
}

// MARK: AccountCard.Kind
extension AccountCard {
	enum Kind {
		/// Stacks the name and address horizontally
		/// When `addCornerRadius`, its shaped is clipped with a corner radius of 12.
		/// Used for example in Account Settings view.
		case display(addCornerRadius: Bool)

		/// Similar to `.display`, but with a smaller vertical padding.
		/// Used for example in Customize Fees view.
		case compact(addCornerRadius: Bool)

		/// Stacks the name and address vertically, while expecting more content on the trailing and bottom sections.
		/// Its shape is clipped with a corner radius of 12.
		/// Used for Home rows.
		case home(tags: [AccountCardTag])

		/// Stacks the name and address vertically, while expecting a view that allows selection on the trailing section.
		/// Its shape is clipped with a corner radius of 12.
		/// Used for example when choosing a receiving account.
		case selection(isSelected: Bool)
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

	/// Behaves same way as `.selection`, showing the name and address vertically, but it is never selected.
	static var details: Self {
		.selection(isSelected: false)
	}
}

private extension AccountCard.Kind {
	var axis: Axis {
		switch self {
		case .display, .compact:
			.horizontal
		case .home, .selection:
			.vertical
		}
	}

	var verticalAlignment: VerticalAlignment {
		switch self {
		case .compact, .display, .selection:
			.center
		case .home:
			.top
		}
	}

	var horizontalPadding: CGFloat {
		switch self {
		case .display, .compact:
			.medium3
		case .home, .selection:
			.medium1
		}
	}

	var verticalPadding: CGFloat {
		switch self {
		case .display, .home, .selection:
			.medium2
		case .compact:
			.small1
		}
	}

	var cornerRadius: CGFloat {
		switch self {
		case let .display(addCornerRadius), let .compact(addCornerRadius):
			addCornerRadius ? .small1 : .zero
		case .home, .selection:
			.small1
		}
	}

	var tag: [AccountCardTag] {
		switch self {
		case let .home(tags):
			tags
		default:
			[]
		}
	}

	var gradientBrightness: CGFloat {
		switch self {
		case .display, .compact, .home:
			.zero
		case let .selection(isSelected):
			isSelected ? -0.1 : .zero
		}
	}
}

extension AccountCardTag {
	var display: String {
		switch self {
		case .dAppDefinition:
			L10n.HomePage.AccountsTag.dAppDefinition
		case .legacy:
			L10n.HomePage.AccountsTag.legacySoftware
		case let .factorSource(fs):
			fs.name
		}
	}
}
