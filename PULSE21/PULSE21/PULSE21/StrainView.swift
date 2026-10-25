import SwiftUI

struct StrainView: View {
    @ObservedObject var health: HealthStore

    var body: some View {
        let result = StrainScorer.calculate(from: health)

        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("STRAIN")
                        .font(.caption.bold())
                        .tracking(2)
                        .foregroundStyle(Color.pulseLime)

                    Text(result.score.map { String(Int($0.rounded())) } ?? "—")
                        .font(.system(size: 68, weight: .bold, design: .rounded))

                    Text("de 21 · esfuerzo diario")
                        .foregroundStyle(Color.pulseMuted)

                    Text(result.explanation)
                        .font(.subheadline)
                        .foregroundStyle(Color.pulseMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(22)
                .background(Color.pulseCard, in: RoundedRectangle(cornerRadius: 22))

                VStack(alignment: .leading, spacing: 12) {
                    Text("¿CÓMO SE CALCULA?")
                        .font(.caption.bold())
                        .tracking(1.5)
                        .foregroundStyle(Color.pulseMuted)

                    Text("El esfuerzo diario es una estimación basada en los datos de actividad y frecuencia cardíaca disponibles en Apple Salud. No es una medición oficial de WHOOP.")
                        .font(.subheadline)
                        .foregroundStyle(Color.pulseMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(Color.pulseCard, in: RoundedRectangle(cornerRadius: 22))
            }
            .padding(20)
        }
        .background(Color.pulseBackground.ignoresSafeArea())
        .navigationTitle("Esfuerzo")
        .navigationBarTitleDisplayMode(.inline)
    }
}
