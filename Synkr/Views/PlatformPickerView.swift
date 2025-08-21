//
//  PlatformPickerView.swift
//  Synkr
//
//  Created by Arnav on 28/07/25.
//

import SwiftUI

struct PlatformPickerView: View {
    let title: String
    let exclude: [Platform]
    let onSelect: (Platform) -> Void

    var body: some View {
        ZStack {
            Color.clear
                .background(.black.gradient)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text(title)
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(.white) 

                ForEach(Platform.allCases.filter { !exclude.contains($0) }, id: \.self) { platform in
                    Button(action: {
                        onSelect(platform)
                    }) {
                        HStack {
                            Image(platform.logoName)
                                .resizable()
                                .frame(width: 24, height: 24)

                            Text(platform.rawValue)
                                .fontWeight(.semibold)
                                .foregroundStyle(.black)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(platform.color)
                        .clipShape(Capsule())
                    }
                }
            }
            .padding()
        }
    }
}




#Preview {
    PlatformPickerView(title: "Select Platform", exclude: []) { platform in
        print("Selected:", platform)
    }
}
