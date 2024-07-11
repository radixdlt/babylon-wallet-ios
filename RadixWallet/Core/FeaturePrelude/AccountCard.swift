import SwiftUI

// MARK: - AccountCard
public struct AccountCard<Trailing: View, Bottom: View>: View {
	let axis: Axis
	let size: Size
	let account: Account
	let trailing: Trailing
	let bottom: Bottom

	public init(
		axis: Axis = .horizontal,
		size: Size = .regular,
		account: Account,
		@ViewBuilder trailing: () -> Trailing,
		@ViewBuilder bottom: () -> Bottom
	) {
		self.axis = axis
		self.size = size
		self.account = account
		self.trailing = trailing()
		self.bottom = bottom()
	}

	public var body: some View {
		VStack(spacing: .zero) {
			top
			bottom
		}
		.padding(size.padding)
		.background {
			LinearGradient(gradient: .init(account.appearanceId), startPoint: .leading, endPoint: .trailing)
		}
	}
}

@MainActor
extension AccountCard {
	private var top: some View {
		HStack(spacing: .zero) {
			switch axis {
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
		VStack(alignment: .leading, spacing: .small1) {
			Text(account.displayName.rawValue)
				.foregroundColor(.app.white)
				.textStyle(.body1Header)

			AddressView(.address(of: account))
				.foregroundColor(.app.whiteTransparent)
				.textStyle(.body2HighImportance)
		}
	}
}

// MARK: AccountCard.Size
extension AccountCard {
	public enum Size {
		case compact
		case regular

		var padding: CGFloat {
			switch self {
			case .compact: .small1
			case .regular: .medium3
			}
		}
	}
}

extension AccountCard where Trailing == EmptyView, Bottom == EmptyView {
	public init(axis: Axis = .horizontal, size: Size = .regular, account: Account) {
		self.init(
			axis: axis,
			size: size,
			account: account,
			trailing: { EmptyView() },
			bottom: { EmptyView() }
		)
	}
}
