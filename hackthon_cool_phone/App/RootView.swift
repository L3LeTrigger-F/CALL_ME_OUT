import SwiftUI

struct RootView: View {
    @State private var showSplash = true
    @Binding var forceHideSplash: Bool
    
    var body: some View {
        ZStack {
            ContentView()
                .opacity((showSplash && !forceHideSplash) ? 0 : 1)
            
            if showSplash && !forceHideSplash {
                ParticleExplosionSplash(isActive: $showSplash)
                // 选择一个样式（取消其他的注释）
                
                // 样式1：默认（推荐）
              //  SplashScreenView(isActive: $showSplash)
                
                // 样式2：极简
                // MinimalSplashScreenView(isActive: $showSplash)
                
                // 样式3：渐变炫彩
                //  GradientSplashScreenView(isActive: $showSplash)
                // LiquidMetalSplash(isActive: $showSplash)
                // 样式4：科技感
                // TechSplashScreenView(isActive: $showSplash)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: showSplash)
    }
}
