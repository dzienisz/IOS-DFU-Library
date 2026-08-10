/*
 * Copyright (c) 2022, Nordic Semiconductor
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice, this
 *    list of conditions and the following disclaimer in the documentation and/or
 *    other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its contributors may
 *    be used to endorse or promote products derived from this software without
 *    specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

import SwiftUI

/// Adaptive glass button styling for iOS 26+, falling back to DfuButtonStyle on earlier systems.
/// Usage:
/// - .dfuButton(role: .active)      // current step — prominent
/// - .dfuButton(role: .secondary)   // previous step — enabled, less emphasis
/// - .dfuButton(role: .destructive)    // current step - destructive
public enum DfuButtonRole {
    case active
    case secondary
    case destructive
}

public struct DfuAdaptiveButtonModifier: ViewModifier {
    @Environment(\.isEnabled) var isEnabled
    let role: DfuButtonRole

    public func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            switch role {
            case .active:
                content
                    .buttonStyle(.glassProminent)
            case .secondary:
                content
                    .buttonStyle(.glass)
            case .destructive:
                content
                    .tint(ThemeColor.error.color)
                    .buttonStyle(.glassProminent)
            }
        } else {
            switch role {
            case .active,
                 .secondary where !isEnabled:
                content
                    .foregroundColor(.white)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 30)
                            .fill(isEnabled ? ThemeColor.buttonEnabledBackground.color : ThemeColor.buttonDisabledBackground.color)
                  )
            case .secondary:
                content
                    .foregroundColor(.primary)
                    .padding(10)
                    .overlay(
                        Capsule()
                            .stroke(
                                isEnabled
                                    ? ThemeColor.buttonEnabledBackground.color
                                    : ThemeColor.buttonDisabledBackground.color
                            )
                    )
            case .destructive:
                content
                    .foregroundColor(.white)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 30)
                            .fill(ThemeColor.error.color)
                  )
            }
        }
    }
}

public extension View {
    /// Apply the DFU adaptive button styling depending on the role and OS version.
    func dfuButton(role: DfuButtonRole) -> some View {
        self.modifier(DfuAdaptiveButtonModifier(role: role))
    }
}

