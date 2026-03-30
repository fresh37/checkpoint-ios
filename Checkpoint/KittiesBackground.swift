//
//  KittiesBackground.swift
//  Checkpoint
//
//  Faded cat photo background layer for the "Kitties" theme.
//  Scuff (orange tabby) drifts lower-left; Chive (tuxedo) upper-right.
//

import SwiftUI

struct KittiesBackground: View {
    let imageNames: [String]

    @State private var float1: CGFloat = 0
    @State private var float2: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            ZStack {
                if imageNames.count > 0 {
                    Image(imageNames[0])
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width * 0.65,
                               height: geo.size.height * 0.5)
                        .clipped()
                        .opacity(0.08)
                        .blur(radius: 3)
                        .offset(x: -geo.size.width * 0.18,
                                y: geo.size.height * 0.22 + float1)
                }
                if imageNames.count > 1 {
                    Image(imageNames[1])
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width * 0.55,
                               height: geo.size.height * 0.45)
                        .clipped()
                        .opacity(0.08)
                        .blur(radius: 3)
                        .offset(x: geo.size.width * 0.22,
                                y: -geo.size.height * 0.12 + float2)
                }
            }
            .allowsHitTesting(false)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 9).repeatForever(autoreverses: true)) {
                float1 = 8
            }
            withAnimation(.easeInOut(duration: 11).repeatForever(autoreverses: true).delay(2.5)) {
                float2 = -7
            }
        }
    }
}
