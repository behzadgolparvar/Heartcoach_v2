import SwiftUI
import UIKit

extension View {
    /// Lets a downward scroll drag dismiss the keyboard. Apply to a ScrollView.
    func dismissableKeyboard() -> some View {
        scrollDismissesKeyboard(.interactively)
    }

    /// Dismisses the keyboard when the user taps an empty area.
    /// Interactive controls (text fields, buttons, pickers) still receive their taps first,
    /// so only taps that fall on blank space trigger the dismiss.
    func hideKeyboardOnTap() -> some View {
        contentShape(Rectangle())
            .onTapGesture {
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder),
                    to: nil, from: nil, for: nil
                )
            }
    }
}
