//
//  AddFactorSource-NameFactorSource+View.swift
//  RadixWallet
//
//  Created by Ghenadie VP on 15.04.2025.
//

extension AddFactorSource.NameFactorSource {
    struct View: SwiftUI.View {
        @Perception.Bindable var store: StoreOf<AddFactorSource.NameFactorSource>
        
        var body: some SwiftUI.View {
            WithPerceptionTracking {
                ScrollView {
                    VStack {
                        header
                        AppTextField(
                            placeholder: "Enter name",
                            text: $store.name.sending(\.view.nameChanged),
                            hint: .info("This can be changed anytime")
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
                        Button("Save", action: action)
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

                Text(store.kind.addFactorTitle)
                    .textStyle(.sheetTitle)
            }
            .foregroundStyle(.app.gray1)
            .multilineTextAlignment(.center)
        }
    }
}
