//
//  ContentView.swift
//  ios_sample_app_pnfpbios
//
//  Created by Muralidharan Ramasamy on 26/04/23.
//

import SwiftUI

struct ContentView: View {

    var body: some View {
        
        //NavigationView {
            SwiftUIWebView(url: URL(string: "https://www.sampleiospnfpbapp.com"))
        //SwiftUIWebView(url: URL(string: "https://www.muraliwebworld.com"))
            //.navigationViewStyle(StackNavigationViewStyle())
        //}
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
