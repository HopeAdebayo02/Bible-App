//
//  ContentView.swift
//  Bible App
//
//  Created by Hope Adebayo on 9/9/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appearance: AppearanceService
    var body: some View {
        MainTabsView()
            .preferredColorScheme(appearance.isDarkMode ? .dark : .light)
    }
}

#Preview {
    ContentView()
}

