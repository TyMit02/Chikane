struct LoadingScreenView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            Color(colorScheme == .dark ? .black : .white)
                .edgesIgnoringSafeArea(.all)
            
            Image(colorScheme == .dark ? "LogoDark" : "LogoLight")
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
        }
    }
}