import SwiftUI

// MARK: - AccountCard
public struct AccountCard<Trailing: View, Bottom: View>: View {
	let kind: Kind
	let account: Account
	let trailing: Trailing
	let bottom: Bottom

	public init(
		kind: Kind,
		account: Account,
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
			LinearGradient(gradient: .init(account.appearanceId), startPoint: .leading, endPoint: .trailing)
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
			Text(account.displayName.rawValue)
				.foregroundColor(.app.white)
				.textStyle(.body1Header)

			Spacer(minLength: .zero)

			AddressView(.address(of: account))
				.foregroundColor(.app.whiteTransparent)
				.textStyle(.body2HighImportance)
		}
	}

	private var verticalCore: some View {
		VStack(alignment: .leading, spacing: .small2) {
			Text(account.displayName.rawValue)
				.foregroundColor(.app.white)
				.textStyle(.body1Header)

			AddressView(.address(of: account))
				.foregroundColor(.app.whiteTransparent)
				.textStyle(.body2HighImportance)
		}
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
		case home
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
}

extension AccountCard where Trailing == EmptyView, Bottom == EmptyView {
	public init(kind: Kind = .display, account: Account) {
		self.init(
			kind: kind,
			account: account,
			trailing: { EmptyView() },
			bottom: { EmptyView() }
		)
	}
}
