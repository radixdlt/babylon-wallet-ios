import SwiftUI

// MARK: - ResourceBalanceButton
public struct ResourceBalanceButton: View {
	public let viewState: ResourceBalance.ViewState
	public let appearance: Appearance
	public let isSelected: Bool?
	public let onTap: () -> Void

	public enum Appearance {
		case assetList
		case transactionReview
	}

	init(_ viewState: ResourceBalance.ViewState, appearance: Appearance, isSelected: Bool? = nil, onTap: @escaping () -> Void) {
		self.viewState = viewState
		self.appearance = appearance
		self.isSelected = isSelected
		self.onTap = onTap
	}

	public var body: some View {
		HStack(alignment: .center, spacing: .small2) {
			Button(action: onTap) {
				ResourceBalanceView(viewState, appearance: viewAppearance, isSelected: isSelected)
					.padding(.vertical, verticalSpacing)
					.padding(.horizontal, horizontalSpacing)
					.contentShape(Rectangle())
					.background(background)
			}
		}
	}

	private var viewAppearance: ResourceBalanceView.Appearance {
		switch appearance {
		case .assetList, .transactionReview:
			.standard
		}
	}

	private var verticalSpacing: CGFloat {
		switch appearance {
		case .assetList:
			switch viewState {
			case .fungible, .nonFungible:
				.medium2
			case .liquidStakeUnit, .poolUnit, .stakeClaimNFT:
				.medium3
			}
		case .transactionReview:
			.medium2
		}
	}

	private var horizontalSpacing: CGFloat {
		switch appearance {
		case .assetList:
			switch viewState {
			case .fungible, .nonFungible:
				.large3
			case .liquidStakeUnit, .poolUnit, .stakeClaimNFT:
				.medium3
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
