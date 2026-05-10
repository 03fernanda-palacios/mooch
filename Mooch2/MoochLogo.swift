import SwiftUI

struct MoochLogo: View {
    var size: CGFloat = 28

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(Color.moochGreen)
                .frame(width: size, height: size)
            Image(systemName: "flame.fill")
                .font(.system(size: size * 0.52, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

struct MoochLogoPill: View {
    var body: some View {
        HStack(spacing: 6) {
            MoochLogo(size: 26)
            Text("MOOCH")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundColor(Color.moochTextPrimary)
                .tracking(1.5)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
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
