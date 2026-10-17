import SwiftUI
import UIKit

enum Keyboard {
    static func dismiss() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

extension View {
    /// Install once near the root: tap anywhere that isn’t a text field/view to dismiss the keyboard.
    func dismissKeyboardOnTap() -> some View {
        background(KeyboardDismissTapInstaller())
    }

    /// After a field becomes focused, scroll it into view (keyboard + bottom bars).
    func scrollToFocused<ID: Hashable>(
        _ id: ID,
        proxy: ScrollViewProxy,
        anchor: UnitPoint = .center,
        when focused: Bool
    ) -> some View {
        onChange(of: focused) { _, isFocused in
            guard isFocused else { return }
            // Wait a beat so the keyboard’s safe-area change lands first.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation(.easeOut(duration: 0.25)) {
                    proxy.scrollTo(id, anchor: anchor)
                }
            }
        }
    }
}

/// Adds a window tap recognizer that ignores taps on `UITextField` / `UITextView`.
private struct KeyboardDismissTapInstaller: UIViewRepresentable {
    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.isUserInteractionEnabled = false
        DispatchQueue.main.async {
            context.coordinator.install(from: view)
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            context.coordinator.install(from: uiView)
        }
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        private static let name = "hi.again.dismissKeyboard"
        private weak var installedOn: UIWindow?

        func install(from view: UIView) {
            guard let window = view.window ?? Self.keyWindow else { return }
            if installedOn === window { return }
            // Move with the key window if the scene changes.
            if let old = installedOn {
                old.gestureRecognizers?
                    .filter { $0.name == Self.name }
                    .forEach { old.removeGestureRecognizer($0) }
            }
            let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
            tap.name = Self.name
            tap.cancelsTouchesInView = false
            tap.delegate = self
            window.addGestureRecognizer(tap)
            installedOn = window
        }

        @objc private func tapped() {
            Keyboard.dismiss()
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            var view = touch.view
            while let current = view {
                if current is UITextField || current is UITextView { return false }
                view = current.superview
            }
            return true
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            true
        }

        private static var keyWindow: UIWindow? {
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap(\.windows)
                .first { $0.isKeyWindow }
        }
    }
}
