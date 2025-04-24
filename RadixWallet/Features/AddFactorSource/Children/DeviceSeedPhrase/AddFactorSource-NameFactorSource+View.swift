extension AddFactorSource.NameFactorSource {
	struct View: SwiftUI.View {
		@Perception.Bindable var store: StoreOf<AddFactorSource.NameFactorSource>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				ScrollView {
					VStack {
						header
						AppTextField(
							placeholder: L10n.NewBiometricFactor.Name.label,
							text: $store.name.sending(\.view.nameChanged),
							hint: .info(L10n.NewBiometricFactor.Name.note)
						)
						Spacer()
					}
					.padding(.medium3)
				}
				.footer {
					WithControlRequirements(
						store.sanitizedName,
						forAction: { store.send(.view(.saveTapped($0))) }
					) { action in
						Button(L10n.Common.save, action: action)
							.buttonStyle(.primaryRectangular)
							.controlState(store.saveButtonControlState)
					}
				}
				.sheet(store: store.scope(state: \.$destination.completion, action: \.destination.completion), content: { _ in
					AddFactorSource.CompletionView()
				})
			}
		}

		var header: some SwiftUI.View {
			VStack(spacing: .small2) {
				Image(store.kind.icon)
					.resizable()
					.frame(.large)

				Text(store.kind.nameFactorTitle)
					.textStyle(.sheetTitle)
			}
			.foregroundStyle(.app.gray1)
			.multilineTextAlignment(.center)
		}
	}
}
