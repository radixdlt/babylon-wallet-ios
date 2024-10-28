import SwiftUI

// MARK: - ResourceBalanceButton
struct ResourceBalanceButton: View {
	let viewState: ResourceBalance.ViewState
	let appearance: Appearance
	let isSelected: Bool?
	let warning: String?
	let onTap: () -> Void

	enum Appearance {
		case assetList
		case transactionReview
	}

	init(
		_ viewState: ResourceBalance.ViewState,
		appearance: Appearance,
		isSelected: Bool? = nil,
		warning: String? = nil,
		onTap: @escaping () -> Void
	) {
		self.viewState = viewState
		self.appearance = appearance
		self.isSelected = isSelected
		self.warning = warning
		self.onTap = onTap
	}

	var body: some View {
		Button(action: onTap) {
			VStack(alignment: .leading, spacing: .small2) {
				ResourceBalanceView(viewState, appearance: .standard, isSelected: isSelected)

				if let warning {
					WarningErrorView(text: warning, type: .warning, useNarrowSpacing: true)
				}
			}
			.padding(.top, topPadding)
			.padding(.horizontal, horizontalSpacing)
			.padding(.bottom, bottomPadding)
			.contentShape(Rectangle())
			.background(background)
		}
	}

	private var topPadding: CGFloat {
		switch appearance {
		case .assetList:
			switch viewState {
			case .fungible:
				.medium1
			case .nonFungible:
				.large3
			case .liquidStakeUnit:
				.medium3
			case .poolUnit, .stakeClaimNFT:
				.medium1
			case .unknown:
				fatalError("Implement")
			}
		case .transactionReview:
			.medium2
		}
	}

	private var bottomPadding: CGFloat {
		switch appearance {
		case .assetList:
			switch viewState {
			case .fungible:
				.medium2
			case .nonFungible:
				.medium1
			case .liquidStakeUnit, .poolUnit, .stakeClaimNFT:
				.medium3
			case .unknown:
				fatalError("Implement")
			}
		case .transactionReview:
			.medium2
		}
	}

	private var horizontalSpacing: CGFloat {
		switch appearance {
		case .assetList:
			switch viewState {
			case .fungible:
				.large3
			case .nonFungible:
				.medium1
			case .liquidStakeUnit:
				.medium3
			case .poolUnit, .stakeClaimNFT:
				.medium2
			case .unknown:
				fatalError("Implement")
			}
		case .transactionReview:
			.medium2
		}
	}

	private var background: Color {
		switch appearance {
		case .assetList:
			.white
		case .transactionReview:
			.app.gray5
		}
	}
}
