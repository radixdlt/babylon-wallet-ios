import SwiftUI

extension View {
        public func toast<Content: View>(
                isPresented: Binding<Bool>,
                onTap: @escaping () -> Void = {},
                @ViewBuilder content: () -> Content
        ) -> some View {
                overlay(alignment: .top) {
                        Toast(content: content)
                                .onTapGesture {
                                        onTap()
                                }
                                .animation(.easeIn(duration: 2.0), value: isPresented.wrappedValue)
                }
        }
}

private struct Toast<Content: View>: View {
        @ViewBuilder let content: Content


        var body: some View {
                content
                        .padding(.horizontal, 12)
                        .padding(16)
                        .background(
                                Capsule()
                                        .foregroundColor(Color.white)
                                        .shadow(color: Color(.black).opacity(0.16), radius: 12, x: 0, y: 5)
                        )
        }
}

