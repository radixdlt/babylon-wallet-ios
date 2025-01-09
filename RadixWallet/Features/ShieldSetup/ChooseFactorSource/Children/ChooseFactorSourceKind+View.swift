import SwiftUI

// MARK: - ChooseFactorSourceKind.View
extension ChooseFactorSourceKind {
	struct View: SwiftUI.View {
		@Perception.Bindable var store: StoreOf<ChooseFactorSourceKind>

		var body: some SwiftUI.View {
			content
				.radixToolbar(title: L10n.SecurityFactors.SelectFactor.title)
				.tint(.app.gray1)
				.foregroundColor(.app.gray1)
		}

		private var content: some SwiftUI.View {
			WithPerceptionTracking {
				ScrollView {
					VStack(spacing: .zero) {
						ForEachStatic(rows) { kind in
							SettingsRow(kind: kind, store: store)
						}
					}
				}
				.background(Color.app.gray5)
			}
		}

		private var rows: [SettingsRow<ChooseFactorSourceKind>.Kind] {
			[
				.header(""),
				model(kind: .device),
				.header(L10n.SecurityFactors.hardware),
				model(kind: .arculusCard),
				model(kind: .ledgerHqHardwareWallet),
				.header(L10n.SecurityFactors.information),
				model(kind: .password),
				model(kind: .offDeviceMnemonic),
			]
		}

		func model(kind: FactorSourceKind) -> SettingsRow<ChooseFactorSourceKind>.Kind {
			let isValidOrCanBe = store.shieldBuilder.isValidOrCanBe(context: store.context, kind: kind)
			if isValidOrCanBe {
				return .model(
					title: kind.title,
					subtitle: kind.details,
					icon: .asset(kind.icon),
					action: .kindTapped(kind)
				)
			} else {
				return .disabled(
					title: kind.title,
					subtitle: kind.details,
					icon: .asset(kind.icon),
					bottom: { disabled.eraseToAnyView() }
				)
			}
		}

		private var disabled: some SwiftUI.View {
			StatusMessageView(
				text: L10n.SecurityFactors.SelectFactor.disabled,
				type: .warning,
				useNarrowSpacing: true,
				useSmallerFontSize: true,
				emphasizedTextStyle: .body2HighImportance
			)
			.onTapGesture {
				store.send(.view(.disabledKindTapped))
			}
		}
	}
}

extension SecurityShieldBuilder {
	func isValidOrCanBe(context: ChooseFactorSourceContext, kind: FactorSourceKind) -> Bool {
		switch context {
		case .primaryThreshold:
			additionOfFactorSourceOfKindToPrimaryThresholdIsValidOrCanBe(factorSourceKind: kind)
		case .primaryOverride:
			additionOfFactorSourceOfKindToPrimaryOverrideIsValidOrCanBe(factorSourceKind: kind)
		case .recovery:
			additionOfFactorSourceOfKindToRecoveryIsValidOrCanBe(factorSourceKind: kind)
		case .confirmation:
			additionOfFactorSourceOfKindToConfirmationIsValidOrCanBe(factorSourceKind: kind)
		}
	}
}
