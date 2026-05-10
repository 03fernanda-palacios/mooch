import SwiftUI

struct MoochLogo: View {
    var size: CGFloat = 28

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(Color.moochGreen)
                .frame(width: size, height: size)
            Image("MoochLogo")
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .foregroundColor(.white)
                .frame(width: size * 0.68, height: size * 0.68)
        }
    }
}

struct MoochLogoPill: View {
    var body: some View {
        HStack(spacing: 7) {
            Image("MoochLogo")
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .foregroundColor(Color.moochGreen)
                .frame(width: 22, height: 22)
            Text("MOOCH")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundColor(Color.moochTextPrimary)
                .tracking(1.5)
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 7)
        .glassCard(12)
    }
}

#Preview {
    VStack(spacing: 16) {
        MoochLogo()
        MoochLogoPill()
    }
    .padding()
    .background(Color.moochBackground)
}
