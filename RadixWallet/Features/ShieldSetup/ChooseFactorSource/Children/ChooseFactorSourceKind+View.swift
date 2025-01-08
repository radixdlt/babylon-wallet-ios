import SwiftUI

// MARK: - ChooseFactorSourceKind.View
extension ChooseFactorSourceKind {
	struct View: SwiftUI.View {
		let store: StoreOf<ChooseFactorSourceKind>

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

		func model(kind: FactorSourceKind, hints: [Hint.ViewState] = []) -> SettingsRow<ChooseFactorSourceKind>.Kind {
			.model(
				title: kind.title,
				subtitle: kind.details,
				hints: hints,
				icon: .asset(kind.icon),
				action: .kindTapped(kind)
			)
		}
	}
}
