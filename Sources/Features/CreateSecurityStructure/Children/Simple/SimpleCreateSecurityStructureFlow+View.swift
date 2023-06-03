import FeaturePrelude

extension SimpleCreateSecurityStructureFlow.State {
	var viewState: SimpleCreateSecurityStructureFlow.ViewState {
		.init(structure: structure)
	}
}

/// PLACEHOLDER
public typealias SecurityQuestionsFactorSource = OffDeviceMnemonicFactorSource

/// PLACEHOLDER
public typealias TrustedContactFactorSource = LedgerHardwareWalletFactorSource

// MARK: - SimpleCreateSecurityStructureFlow.View
extension SimpleCreateSecurityStructureFlow {
	public struct ViewState: Equatable {
		let structure: NewStructure
		var newPhoneConfirmer: SecurityQuestionsFactorSource? {
			structure.newPhoneConfirmer
		}

		var lostPhoneHelper: TrustedContactFactorSource? {
			structure.lostPhoneHelper
		}
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<SimpleCreateSecurityStructureFlow>

		public init(store: StoreOf<SimpleCreateSecurityStructureFlow>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack {
					SecurityStructureTutorialHeader()

					FactorForRoleView<ConfirmationRoleTag, SecurityQuestionsFactorSource>(
						factorSet: viewStore.newPhoneConfirmer
					) {
						viewStore.send(.selectNewPhoneConfirmer)
					}

					FactorForRoleView<RecoveryRoleTag, TrustedContactFactorSource>(
						factorSet: viewStore.lostPhoneHelper
					) {
						viewStore.send(.selectLostPhoneHelper)
					}

					Spacer(minLength: 0)
				}
			}
		}
	}
}

extension BaseFactorSourceProtocol {
	var selectedFactorDisplay: String {
		kind.selectedFactorDisplay
	}
}

extension FactorSourceKind {
	var selectedFactorDisplay: String {
		switch self {
		// FIXME: Strings
		case .device:
			return "Phone"
		case .ledgerHQHardwareWallet:
			return "Ledger"
		case .offDeviceMnemonic:
			return "Seed phrase"
		}
	}
}

extension RoleProtocol {
	static var titleSimpleFlow: String {
		role.titleSimpleFlow
	}

	static var subtitleSimpleFlow: String {
		role.subtitleSimpleFlow
	}
}

extension SecurityStructureRole {
	var titleSimpleFlow: String {
		switch self {
		case .primary:
			fatalError("not used")
		case .confirmation:
			return "New phone confirmer"
		case .recovery:
			return "Lost phone helper"
		}
	}

	var subtitleSimpleFlow: String {
		switch self {
		case .primary:
			fatalError("not used")
		case .confirmation:
			return "Set security questions that are trigger when you move to a new phone"
		case .recovery:
			return "Select a third-party who can help you recover your account if you lose your phone."
		}
	}
}

// MARK: - FactorForRoleView
public struct FactorForRoleView<Role: RoleProtocol, Factor: BaseFactorSourceProtocol>: SwiftUI.View {
	public let factorSet: Factor?
	public let action: @Sendable () -> Void

	public init(factorSet: Factor? = nil, action: @escaping @Sendable () -> Void) {
		self.factorSet = factorSet
		self.action = action
	}

	public var body: some View {
		SelectFactorView(
			title: Role.titleSimpleFlow,
			subtitle: Role.subtitleSimpleFlow,
			factorSet: factorSet,
			action: action
		)
		.frame(maxWidth: .infinity)
	}
}

// MARK: - SelectFactorView
public struct SelectFactorView: SwiftUI.View {
	public let title: String
	public let subtitle: String
	public let factorSet: BaseFactorSourceProtocol?
	public let action: @Sendable () -> Void
	public init(
		title: String,
		subtitle: String,
		factorSet: BaseFactorSourceProtocol? = nil,
		action: (@Sendable () -> Void)? = nil
	) {
		self.title = title
		self.subtitle = subtitle
		self.factorSet = factorSet
		self.action = action ?? {
			loggerGlobal.debug("\(title) factor selection tapped")
		}
	}

	public var body: some SwiftUI.View {
		VStack(alignment: .leading, spacing: .medium2) {
			Text(title)
				.font(.app.sectionHeader)

			Text(subtitle)
				.font(.app.body2Header)
				.foregroundColor(.app.gray3)

			Button(action: action) {
				HStack {
					// FIXME: Strings
					Text(factorSet?.selectedFactorDisplay ?? "None set")
						.font(.app.body1Header)

					Spacer(minLength: 0)

					Image(asset: AssetResource.chevronRight)
				}
				.foregroundColor(.app.gray3)
			}
			.cornerRadius(.medium2)
			.frame(maxWidth: .infinity)
			.padding()
			.background(.app.gray5)
		}
		.padding()
		.frame(maxWidth: .infinity)
	}
}

// MARK: - SecurityStructureTutorialHeader
public struct SecurityStructureTutorialHeader: SwiftUI.View {
	public let action: () -> Void
	public init(
		action: @escaping @Sendable () -> Void = { loggerGlobal.debug("MFA: How does it work? Button tapped") }
	) {
		self.action = action
	}

	public var body: some SwiftUI.View {
		VStack(spacing: .medium1) {
			Text("Multi-Factor Setup") // FIXME: Strings
				.font(.app.sheetTitle)

			Text("You can assign diffrent factors to different actions on Radix Accounts")
				.font(.app.body2Regular)

			Button("How does it work?", action: action)
				.buttonStyle(.info)
				.padding(.horizontal, .large2)
				.padding(.bottom, .medium1)
		}
		.padding(.medium1)
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - SimpleCreateSecurityStructureFlow_Preview
struct SimpleCreateSecurityStructureFlow_Preview: PreviewProvider {
	static var previews: some View {
		SimpleCreateSecurityStructureFlow.View(
			store: .init(
				initialState: .previewValue,
				reducer: SimpleCreateSecurityStructureFlow()
			)
		)
	}
}

extension SimpleCreateSecurityStructureFlow.State {
	public static let previewValue = Self()
}
#endif
