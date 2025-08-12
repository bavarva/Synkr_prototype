//
//  ContentView.swift
//  SwipeDemo
//
//  Created by Arnav on 04/08/25.
//

import SwiftUI

struct WalkthroughView: View {
    @State private var currentIndex: Int = 0
    private let display : [Titles] = [Titles(subheading2: "", heading: "Synkr..", description: "Keep your music in sync across platforms"), Titles(subheading2: "One Tap Transfer",  heading: "", description: "Choose source and destination, pick playlists, and you’re done."), Titles(subheading2: "Text To Playlists",  heading: "", description: "Have a list of songs in notes or chat? Let Synkr build your playlist.")]
    
    func buildButton(label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .fontWeight(.semibold)
                .frame(width: 300, height: 50)
                .background(Color(red: 255/255, green: 242/255, blue: 224/255))
                .foregroundColor(.black)
                .cornerRadius(30)
                .shadow(radius: 4)
        }
    }
    
    func slideView(for content: Titles, at index: Int) -> some View {
        VStack(){
            Spacer()
            if(index == 1){
                Image("oneTap")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 250)
            }
            if(index == 2){
                Image("textToPlaylist")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 350)
            }
            
            Text(content.heading)
                .font(.custom("Always In My Heart", size: 162))
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(Color(red: 255/255, green: 242/255, blue: 224/255))
                .lineLimit(1)
                .minimumScaleFactor(0.1)
            
            if index != 0 {
                Spacer().frame(height: 40)
            }
            Text(content.subheading2)
                .font(.system(size: 38, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(Color(red: 255/255, green: 242/255, blue: 224/255))
                .padding(index == 0 ? .init() : .all)
            
            Text(content.description)
                .font(.title)
                .foregroundColor(.gray.opacity(0.6))
                .padding(.horizontal)
            
            if index == 0 {
                Spacer()
            } else {
                Spacer().frame(height: 42)
            }
            
            if index != 2 {
                buildButton(label: "Continue") {
                    if currentIndex < display.count - 1 {
                        withAnimation {
                            currentIndex += 1
                        }
                    }
                }
            } else {
                buildButton(label: "Get Started") {
                    // Perform some action
                }
            }
            Spacer().frame(height: 20)
        }
        .padding()
    }
    
    var body: some View {
        ZStack{
            VStack {
                TabView(selection: $currentIndex) {
                    ForEach(display.indices, id: \.self) { index in
                        let content = display[index]
                        slideView(for: content, at: index)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page)
                .indexViewStyle(.page(backgroundDisplayMode: .never))
            }
            .padding()
        }.background(.black.gradient)
    }
}

#Preview {
    WalkthroughView()
}
