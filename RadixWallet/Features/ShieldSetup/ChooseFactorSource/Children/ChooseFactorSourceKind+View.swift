import SwiftUI

// MARK: - ChooseFactorSourceKind.View
extension ChooseFactorSourceKind {
	struct View: SwiftUI.View {
		@Perception.Bindable var store: StoreOf<ChooseFactorSourceKind>

		var body: some SwiftUI.View {
			content
				.radixToolbar(title: "Select Factor Type")
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
			if canBeUsed(kind: kind) {
				.model(
					title: kind.title,
					subtitle: kind.details,
					icon: .asset(kind.icon),
					action: .kindTapped(kind)
				)
			} else {
				.disabled(
					title: kind.title,
					subtitle: kind.details,
					icon: .asset(kind.icon),
					bottom: { disabled.eraseToAnyView() }
				)
			}
		}

		private var disabled: some SwiftUI.View {
			StatusMessageView(
				text: "Can't currently be used here. **Learn why**",
				type: .warning,
				useNarrowSpacing: true,
				useSmallerFontSize: true,
				emphasizedTextStyle: .body2HighImportance
			)
			.onTapGesture {
				store.send(.view(.disabledKindTapped))
			}
		}

		private func canBeUsed(kind: FactorSourceKind) -> Bool {
			store.shieldBuilder.additionOfFactorSourceOfKindToRecoveryIsValidOrCanBe(factorSourceKind: kind)
		}
	}
}
