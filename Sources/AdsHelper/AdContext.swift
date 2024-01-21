//
//  AdContext.swift
//  
//
//  Created by Fausto Ristagno on 21/01/24.
//

import SwiftUI


public extension View {
    func adContext() -> some View {
        self
            .adBannerContext()
            .adInterstitialContext()
    }
}
